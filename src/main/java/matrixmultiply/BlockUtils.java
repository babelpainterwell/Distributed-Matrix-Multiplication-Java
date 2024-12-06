package matrixmultiply;

public class BlockUtils {

    // Parse block string like "1,2;3,4" into 2D array
    public static double[][] parseBlock(String blockData) {
        String[] rows = blockData.split(";");
        double[][] block = new double[rows.length][];
        for (int i = 0; i < rows.length; i++) {
            String[] cols = rows[i].split(",");
            block[i] = new double[cols.length];
            for (int j = 0; j < cols.length; j++) {
                block[i][j] = Double.parseDouble(cols[j]);
            }
        }
        return block;
    }

    // local matrix multiplication
    // GIVEN BY CHATGPT
    // GIVEN BY CHATGPT
    // GIVEN BY CHATGPT
    public static double[][] multiplyBlocks(double[][] A, double[][] B) {
        int aRows = A.length;
        int aCols = A[0].length;
        int bRows = B.length;
        int bCols = B[0].length;
        // Assumes aCols == bRows
        double[][] C = new double[aRows][bCols];
        for (int i = 0; i < aRows; i++) {
            for (int j = 0; j < bCols; j++) {
                double sum = 0.0;
                for (int k = 0; k < aCols; k++) {
                    sum += A[i][k] * B[k][j];
                }
                C[i][j] = sum;
            }
        }
        return C;
    }

    // Addition operation of two blocks for each region 
    public static double[][] addBlocks(double[][] A, double[][] B) {
        int rows = A.length;
        int cols = A[0].length;
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                A[i][j] += B[i][j];
            }
        }
        return A;
    }

    // Convert block to string "1.0,2.0;3.0,4.0"
    public static String blockToString(double[][] block) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < block.length; i++) {
            if (i > 0) sb.append(";");
            for (int j = 0; j < block[i].length; j++) {
                if (j > 0) sb.append(",");
                sb.append(block[i][j]);
            }
        }
        return sb.toString();
    }
}
