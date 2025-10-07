import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

object TeraSortByCaps {
  def main(arguments: Array[String]): Unit = {

    // Take the arguments for input and output path
    if (arguments.length < 2) {
      println("Incorrect Usage, Correct Usage: TeraSortByCaps <input_path> <output_path>")
      System.exit(1)
    }

    val inputPath = arguments(0)
    val outputPath = arguments(1)

    // Create Spark session for Tera Sorting by Year Cap
    val sparkSion = SparkSession.builder()
      .appName("Tera Sorting By Year Cap")
      .getOrCreate()

    import sparkSion.implicits._

    // Define the simple schema for the serialCaps
    val serialYearSchema = StructType(Array(
      StructField("year", IntegerType, nullable = false),
      StructField("serial", StringType, nullable = false)
    ))

    // Read CSV from HDFS based on the input path and ignore header
    val capsDF = sparkSion.read
      .option("header", "false")
      .schema(serialYearSchema)
      .csv(inputPath)

    // Filter out future caps (year > 2025) and sort as per the requirement doc
    val sortedDF = capsDF
      .filter($"year" <= 2025)
      .orderBy($"year".desc, $"serial".asc)

    // Write results back to HDFS as CSV to be opened later in local
    sortedDF.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "false")
      .csv(outputPath)

    // End the Spark session
    sparkSion.stop()
  }
}