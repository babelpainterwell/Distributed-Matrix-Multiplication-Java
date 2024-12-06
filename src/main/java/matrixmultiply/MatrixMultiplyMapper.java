package matrixmultiply;

import java.io.IOException;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Mapper;

public class MatrixMultiplyMapper extends Mapper<LongWritable, Text, Text, Text> {

    int numBlockRowsC;
    int numBlockColsC;

    @Override
    // get the number of block rows and columns for matrix C
    protected void setup(Context context) throws IOException, InterruptedException {
        numBlockRowsC = context.getConfiguration().getInt("numBlockRowsC", 1);
        numBlockColsC = context.getConfiguration().getInt("numBlockColsC", 1);
    }

    @Override
    protected void map(LongWritable key, Text value, Context context)
            throws IOException, InterruptedException {
        // Line format: M i j blockData
        // M is either 'A' or 'B'
        // i,j are block indices
        // blockData is something like "1,2;3,4"

        String line = value.toString();
        String[] parts = line.split("\\s+");
        if (parts.length < 4) return; // skip lines with less than 4 parts

        String matrixName = parts[0];
        int i = Integer.parseInt(parts[1]);
        int j = Integer.parseInt(parts[2]);
        String blockData = parts[3];

        if (matrixName.equals("A")) {
            int I = i; // A block at (i,k)
            int K = j;
            for (int J = 0; J < numBlockColsC; J++) {
                // key = (I,J), formatted as "I_J"
                String outKey = I + "_" + J;
                // value = "A K blockData, delimited by space"
                String outVal = "A " + K + " " + blockData;
                context.write(new Text(outKey), new Text(outVal));
            }
        } else if (matrixName.equals("B")) {
            int K = i;
            int J = j;
            for (int I = 0; I < numBlockRowsC; I++) {
                String outKey = I + "_" + J;
                String outVal = "B " + K + " " + blockData;
                context.write(new Text(outKey), new Text(outVal));
            }
        }
    }
}
