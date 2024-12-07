SHELL := /bin/bash

A_ROWS ?= 8000
A_COLS ?= 6000
B_ROWS ?= 6000
B_COLS ?= 4000

BLOCK_SIZE ?= 200
CLUSTER_CORE_NODES ?= 3
CLUSTER_INSTANCE_TYPE ?= m4.large
aws.primary.num.nodes ?= 1

hadoop.root=/usr/local/hadoop-3.3.5
jar.name=matrix-multiply-1.0.jar
jar.path=target/${jar.name}
job.name=matrixmultiply.MatrixMultiplyDriver

# Compute block-level dimensions using awk for integer division
numBlockRowsA=$(shell awk 'BEGIN{print int('$(A_ROWS)'/'$(BLOCK_SIZE)')}')
numBlockColsA=$(shell awk 'BEGIN{print int('$(A_COLS)'/'$(BLOCK_SIZE)')}')
numBlockRowsB=$(shell awk 'BEGIN{print int('$(B_ROWS)'/'$(BLOCK_SIZE)')}')
numBlockColsB=$(shell awk 'BEGIN{print int('$(B_COLS)'/'$(BLOCK_SIZE)')}')
numBlockRowsC=$(shell awk 'BEGIN{print int('$(A_ROWS)'/'$(BLOCK_SIZE)')}')
numBlockColsC=$(shell awk 'BEGIN{print int('$(B_COLS)'/'$(BLOCK_SIZE)')}')

# Local input directory parameterized by BLOCK_SIZE
local.input=input_large_block_$(BLOCK_SIZE)
local.output=output-local-BS$(BLOCK_SIZE)
local.log-local=log-local-BS$(BLOCK_SIZE)

# AWS directories parameterized by BLOCK_SIZE and CLUSTER_CORE_NODES
aws.emr.release=emr-6.10.0
aws.region=us-east-1
aws.bucket.name=cs6240-bucket-wellzhang-matrixmult

# The input is tied to the BLOCK_SIZE since we partition the data by block size.
aws.input=input-BS$(BLOCK_SIZE)

# Output and logs vary by both BLOCK_SIZE and CLUSTER_CORE_NODES,
# allowing multiple runs with different cluster sizes to produce separate outputs.
aws.output=output-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES)
aws.log.dir=log-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES)

jar:
	mvn clean package

clean-local-input:
	rm -rf ${local.input}

ensure-log-dir:
	mkdir -p ${local.log-local}

clean-local-output:
	rm -rf ${local.output}*
	rm -rf ${local.log-local}*

# Run the program locally
local: clean-local-output jar ensure-log-dir
	@echo "numBlockRowsC=$(numBlockRowsC), numBlockColsC=$(numBlockColsC), BLOCK_SIZE=$(BLOCK_SIZE)"
	hadoop jar ${jar.path} ${local.input} ${local.output} $(numBlockRowsC) $(numBlockColsC) $(BLOCK_SIZE) > ${local.log-local}/mapreduce-job.log 2>&1 || (cat ${local.log-local}/mapreduce-job.log && false)

make-bucket:
	aws s3 mb s3://${aws.bucket.name} --region ${aws.region} || true

upload-input-aws: make-bucket
	aws s3 sync ${local.input} s3://${aws.bucket.name}/${aws.input} --region ${aws.region}

delete-output-aws:
	aws s3 rm s3://${aws.bucket.name}/${aws.output} --recursive --region ${aws.region} || true

upload-app-aws: jar
	aws s3 cp ${jar.path} s3://${aws.bucket.name}/${jar.name} --region ${aws.region}

# Run on AWS EMR with parameterized input/output
aws: upload-app-aws upload-input-aws delete-output-aws
	aws emr create-cluster \
		--name "MatrixMultiply MR Cluster" \
		--release-label ${aws.emr.release} \
		--region ${aws.region} \
		--instance-groups '[{"InstanceCount":'${aws.primary.num.nodes}',"InstanceGroupType":"MASTER","InstanceType":"'${CLUSTER_INSTANCE_TYPE}'"},{"InstanceCount":'${CLUSTER_CORE_NODES}',"InstanceGroupType":"CORE","InstanceType":"'${CLUSTER_INSTANCE_TYPE}'"}]' \
		--applications Name=Hadoop \
		--steps '[{"Args":["s3://'${aws.bucket.name}'/'${aws.input}'","s3://'${aws.bucket.name}'/'${aws.output}'","'$(numBlockRowsC)'","'$(numBlockColsC)'","'$(BLOCK_SIZE)'"], "Type":"CUSTOM_JAR","Jar":"s3://'${aws.bucket.name}'/'${jar.name}'","ActionOnFailure":"TERMINATE_CLUSTER","Name":"MatrixMultiplyJob"}]' \
		--log-uri s3://${aws.bucket.name}/${aws.log.dir} \
		--use-default-roles \
		--enable-debugging \
		--auto-terminate

clean-local-output-aws:
	rm -rf output-aws-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES)
	rm -rf log-aws-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES)

download-output-aws: clean-local-output-aws
	mkdir -p output-aws-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES)
	mkdir -p log-aws-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES)
	aws s3 sync s3://${aws.bucket.name}/${aws.output} output-aws-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES) --region ${aws.region}
	aws s3 sync s3://${aws.bucket.name}/${aws.log.dir} log-aws-BS$(BLOCK_SIZE)-N$(CLUSTER_CORE_NODES) --region ${aws.region}
