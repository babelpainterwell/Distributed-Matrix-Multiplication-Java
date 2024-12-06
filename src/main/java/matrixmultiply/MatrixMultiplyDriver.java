package matrixmultiply;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.IntWritable; 
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

public class MatrixMultiplyDriver {
    public static void main(String[] args) throws Exception {

        if (args.length < 4) {
            System.err.println("Usage: MatrixMultiplyDriver <input> <output> <numBlockRowsC> <numBlockColsC>");
            System.exit(-1);
        }

        // System.out.println("args.length: " + args.length);
        // System.out.println("args[0]: " + args[0]);
        // System.out.println("args[1]: " + args[1]);
        // System.out.println("args[2]: " + args[2]);
        // System.out.println("args[3]: " + args[3]);

        String inputPath = args[1];
        String outputPath = args[2];
        int numBlockRowsC = Integer.parseInt(args[3]);
        int numBlockColsC = Integer.parseInt(args[4]);

        Configuration conf = new Configuration();
        conf.setInt("numBlockRowsC", numBlockRowsC);
        conf.setInt("numBlockColsC", numBlockColsC);

        Job job = Job.getInstance(conf, "Block Matrix Multiplication");
        job.setJarByClass(MatrixMultiplyDriver.class);

        job.setMapperClass(MatrixMultiplyMapper.class);
        job.setReducerClass(MatrixMultiplyReducer.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        job.setInputFormatClass(TextInputFormat.class);
        job.setOutputFormatClass(TextOutputFormat.class);

        TextInputFormat.addInputPath(job, new Path(inputPath));
        Path outputDir = new Path(outputPath);

        FileSystem fs = FileSystem.get(conf);
        if (fs.exists(outputDir)) {
            fs.delete(outputDir, true);
        }

        TextOutputFormat.setOutputPath(job, outputDir);

        // Set the number of reducers to the number of C blocks
        int numReducers = numBlockRowsC * numBlockColsC;
        job.setNumReduceTasks(numReducers);

        // Set custom partitioner to ensure each (i,j) goes to a unique reducer
        job.setPartitionerClass(BlockPartitioner.class);

        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}
