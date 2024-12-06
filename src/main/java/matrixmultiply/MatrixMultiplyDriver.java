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

        String inputPath = args[0];
        String outputPath = args[1];
        int numBlockRowsC = Integer.parseInt(args[2]);
        int numBlockColsC = Integer.parseInt(args[3]);

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

        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}
