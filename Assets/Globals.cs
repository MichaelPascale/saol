using Parquet.Serialization;


namespace SAOL {

    static class Options {
        public static ParquetSerializerOptions PARQUET_OPS = new ParquetSerializerOptions {CompressionLevel = System.IO.Compression.CompressionLevel.Optimal};
    }
}