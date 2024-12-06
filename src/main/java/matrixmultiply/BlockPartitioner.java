package matrixmultiply;

import org.apache.hadoop.conf.Configurable;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Partitioner;

public class BlockPartitioner extends Partitioner<Text, Text> implements Configurable {

    private int numBlockRowsC;
    private int numBlockColsC;
    private Configuration conf;

    @Override
    public void setConf(Configuration conf) {
        this.conf = conf;
        this.numBlockRowsC = conf.getInt("numBlockRowsC", 1);
        this.numBlockColsC = conf.getInt("numBlockColsC", 1);
    }

    @Override
    public Configuration getConf() {
        return this.conf;
    }

    @Override
    public int getPartition(Text key, Text value, int numReduceTasks) {
        // Key format: "i_j"
        String[] parts = key.toString().split("_");
        int i = Integer.parseInt(parts[0]);
        int j = Integer.parseInt(parts[1]);

        // Each (i,j) maps to a unique reducer: partition = i * numBlockColsC + j
        int partition = i * numBlockColsC + j;
        return partition;
    }
}
