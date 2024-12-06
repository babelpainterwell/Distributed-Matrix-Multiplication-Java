package matrixmultiply;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Reducer;

public class MatrixMultiplyReducer extends Reducer<Text, Text, Text, Text> {

    int numBlockRowsC;
    int numBlockColsC;

    @Override
    protected void setup(Context context) throws IOException, InterruptedException {
        numBlockRowsC = context.getConfiguration().getInt("numBlockRowsC", 1);
        numBlockColsC = context.getConfiguration().getInt("numBlockColsC", 1);
    }

    @Override
    protected void reduce(Text key, Iterable<Text> values, Context context)
            throws IOException, InterruptedException {
        // key = i_j
        // values = ["A k blockAData", ... , "B k blockBData", ...]

        Map<Integer, double[][]> A_blocks = new HashMap<>();
        Map<Integer, double[][]> B_blocks = new HashMap<>();

        String keyStr = key.toString();
        String[] ij = keyStr.split("_");
        int I = Integer.parseInt(ij[0]);
        int J = Integer.parseInt(ij[1]);

        for (Text val : values) {
            String[] parts = val.toString().split("\\s+", 3);
            // parts[0] = A or B
            // parts[1] = k
            // parts[2] = blockData
            String matrixName = parts[0];
            int K = Integer.parseInt(parts[1]);
            String blockData = parts[2];

            double[][] block = BlockUtils.parseBlock(blockData);
            if (matrixName.equals("A")) {
                A_blocks.put(K, block);
            } else {
                B_blocks.put(K, block);
            }
        }

        // Multiply
        // The result block size depends on A block rows and B block columns
        // Assuming A and B blocks are compatible:
        // Let's take dimensions from first A block if available
        double[][] C_ij = null; // initialize result block to null

        // For each k in intersection
        for (Integer K : A_blocks.keySet()) {
            if (B_blocks.containsKey(K)) {
                double[][] A_block = A_blocks.get(K);
                double[][] B_block = B_blocks.get(K);

                // perform local matrix multiplication
                double[][] product = BlockUtils.multiplyBlocks(A_block, B_block);
                if (C_ij == null) {
                    C_ij = product;
                } else {
                    C_ij = BlockUtils.addBlocks(C_ij, product);
                }
            }
        }

        if (C_ij != null) {
            String cBlockStr = BlockUtils.blockToString(C_ij);
            context.write(key, new Text(cBlockStr));
        }
    }
}
