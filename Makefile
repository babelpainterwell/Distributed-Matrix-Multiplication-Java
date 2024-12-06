SHELL := /bin/bash

# Variables
hadoop.root=/usr/local/hadoop-3.3.5
jar.name=matrix-multiply-1.0.jar
jar.path=target/${jar.name}
job.name=matrixmultiply.MatrixMultiplyDriver

# Specify matrix dimensions and block size
A_ROWS=40000
A_COLS=60000
B_ROWS=60000
B_COLS=40000
BLOCK=2000

# Compute block-level dimensions using awk for integer division
numBlockRowsA=$(shell awk 'BEGIN{print int('$(A_ROWS)'/'$(BLOCK)')}')
numBlockColsA=$(shell awk 'BEGIN{print int('$(A_COLS)'/'$(BLOCK)')}')
numBlockRowsB=$(shell awk 'BEGIN{print int('$(B_ROWS)'/'$(BLOCK)')}')
numBlockColsB=$(shell awk 'BEGIN{print int('$(B_COLS)'/'$(BLOCK)')}')
numBlockRowsC=$(shell awk 'BEGIN{print int('$(A_ROWS)'/'$(BLOCK)')}')
numBlockColsC=$(shell awk 'BEGIN{print int('$(B_COLS)'/'$(BLOCK)')}')

# Local and AWS variables
local.input=input-large
local.output=output-local
local.log-local=log-local

aws.emr.release=emr-6.10.0
aws.region=us-east-1
aws.bucket.name=cs6240-bucket-wellzhang-matrixmult
aws.input=input
aws.output=output
aws.log.dir=log
aws.primary.num.nodes=1
aws.core.num.nodes=5
aws.instance.type=m4.large

# -----------------------------------------------------------

jar:
	mvn clean package

clean-local-input:
	rm -rf ${local.input}

ensure-log-dir:
	mkdir -p ${local.log-local}

clean-local-output:
	rm -rf ${local.output}*
	rm -rf ${local.log-local}*


# GIVEN BY CHATGPT
# GIVEN BY CHATGPT
# GIVEN BY CHATGPT
# Generate synthetic data for matrix multiplication as a separate step
generate-data: clean-local-input
	@echo "Generating data with A: $(A_ROWS)x$(A_COLS), B: $(B_ROWS)x$(B_COLS), block=$(BLOCK)"
	@echo "A_block_rows=$(numBlockRowsA), A_block_cols=$(numBlockColsA), B_block_rows=$(numBlockRowsB), B_block_cols=$(numBlockColsB)"
	mkdir -p ${local.input}
	@for (( i=0; i<$(numBlockRowsA); i++ )); do \
	  for (( k=0; k<$(numBlockColsA); k++ )); do \
	    block_data=""; \
	    for (( rr=1; rr<=$(BLOCK); rr++ )); do \
	      row_data=""; \
	      for (( cc=1; cc<=$(BLOCK); cc++ )); do \
	        val=$$(awk -v seed=$$RANDOM 'BEGIN{srand(seed); printf("%.4f", rand())}'); \
	        if [ -z "$$row_data" ]; then row_data="$$val"; else row_data="$$row_data,$$val"; fi; \
	      done; \
	      if [ -z "$$block_data" ]; then block_data="$$row_data"; else block_data="$$block_data;$$row_data"; fi; \
	    done; \
	    echo "A $$i $$k $$block_data" >> ${local.input}/A_blocks.txt; \
	  done; \
	done; \
	for (( k=0; k<$(numBlockRowsB); k++ )); do \
	  for (( j=0; j<$(numBlockColsB); j++ )); do \
	    block_data=""; \
	    for (( rr=1; rr<=$(BLOCK); rr++ )); do \
	      row_data=""; \
	      for (( cc=1; cc<=$(BLOCK); cc++ )); do \
	        val=$$(awk -v seed=$$RANDOM 'BEGIN{srand(seed); printf("%.4f", rand())}'); \
	        if [ -z "$$row_data" ]; then row_data="$$val"; else row_data="$$row_data,$$val"; fi; \
	      done; \
	      if [ -z "$$block_data" ]; then block_data="$$row_data"; else block_data="$$block_data;$$row_data"; fi; \
	    done; \
	    echo "B $$k $$j $$block_data" >> ${local.input}/B_blocks.txt; \
	  done; \
	done;

# Runs the program locally
# Run 'make generate-data' first 
local: clean-local-output jar ensure-log-dir
	@echo "numBlockRowsC=$(numBlockRowsC), numBlockColsC=$(numBlockColsC)"
	hadoop jar ${jar.path} ${local.input} ${local.output} $(numBlockRowsC) $(numBlockColsC) > ${local.log-local}/mapreduce-job.log 2>&1 || (cat ${local.log-local}/mapreduce-job.log && false)

make-bucket:
	aws s3 mb s3://${aws.bucket.name} --region ${aws.region} || true

upload-input-aws: make-bucket 
	aws s3 sync ${local.input} s3://${aws.bucket.name}/${aws.input} --region ${aws.region}

delete-output-aws:
	aws s3 rm s3://${aws.bucket.name}/ --recursive --exclude "*" --include "${aws.output}*" --region ${aws.region} || true

upload-app-aws: jar
	aws s3 cp ${jar.path} s3://${aws.bucket.name}/${jar.name} --region ${aws.region}

aws: upload-app-aws upload-input-aws delete-output-aws
	aws emr create-cluster \
		--name "MatrixMultiply MR Cluster" \
		--release-label ${aws.emr.release} \
		--region ${aws.region} \
		--instance-groups '[{"InstanceCount":'${aws.primary.num.nodes}',"InstanceGroupType":"MASTER","InstanceType":"'${aws.instance.type}'"},{"InstanceCount":'${aws.core.num.nodes}',"InstanceGroupType":"CORE","InstanceType":"'${aws.instance.type}'"}]' \
		--applications Name=Hadoop \
		--steps '[{"Args":["s3://'${aws.bucket.name}'/'${aws.input}'","s3://'${aws.bucket.name}'/'${aws.output}'","$(numBlockRowsC)","$(numBlockColsC)"], "Type":"CUSTOM_JAR","Jar":"s3://'${aws.bucket.name}'/'${jar.name}'","ActionOnFailure":"TERMINATE_CLUSTER","Name":"MatrixMultiplyJob"}]' \
		--log-uri s3://${aws.bucket.name}/${aws.log.dir} \
		--use-default-roles \
		--enable-debugging \
		--auto-terminate

clean-local-output-aws:
	rm -rf ${local.output}-aws*
	rm -rf ${local.log-local}-aws*

download-output-aws: clean-local-output-aws
	mkdir -p ${local.output}-aws
	mkdir -p ${local.log-local}-aws
	aws s3 sync s3://${aws.bucket.name}/${aws.output} ${local.output}-aws --region ${aws.region}
	aws s3 sync s3://${aws.bucket.name}/${aws.log.dir} ${local.log-local}-aws --region ${aws.region}
