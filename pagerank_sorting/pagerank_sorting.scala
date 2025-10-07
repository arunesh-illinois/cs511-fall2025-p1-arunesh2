// PageRank(node) = (1-d)/N + d * Σ(PR(incoming_node) / outgoing_links(incoming_node))
// where d = damping factor, N = total number of nodes, tolerance = iteration until convergence

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.rdd.RDD

object PageRankImplementation {
    def main(arguments: Array[String]): Unit = {
        if (arguments.length < 2) {
            println("Incorrect Usage, Correct: PageRankImplementation <input> <output>")
            System.exit(1)
        }

        // Get the Input,Output path from arguments
        val inputPath = arguments(0)
        val outputPath = arguments(1)

        // Pre defined damping, total iterations and tolerance values
        val d = 0.85
        val tol = 0.0001
        val totalIterations = 100

        // Start a spark session
        val sparkSion = SparkSession.builder().appName("Page Rank Impl").getOrCreate()

        val sparkCtxt = sparkSion.sparkContext

        // Fetch the edges from the input file in HDFS (src, dest)
        val graphEdges = sparkCtxt.textFile(inputPath)
            .map { line =>
                val parts = line.split(",")
                (parts(0).toInt, parts(1).toInt)
            }

        val distinctNodes = graphEdges.flatMap { case (src, dest) => Seq(src, dest)}
            .distinct()
            .collect()
            .toSet

        val totalNodes = distinctNodes.size

        // Create the adjacency list for pageRank
        val adjList = graphEdges.groupByKey().cache()

        // List of Nodes with links and no outgoing links
        val nodesWithEdges = adjList.keys.collect().toSet

        // Set initial rank for all nodes with 1.0/totalNodes
        var ranks = sparkCtxt.parallelize(distinctNodes.toSeq.map(node => (node, 1.0/totalNodes)))

        // Iteration conditions
        var currItr = 0
        var converged = false

        // Page Rank loop
        while (!converged && currItr < totalIterations) {
            // Calculate contributions
            val contributions = adjList.join(ranks).flatMap {
                case (node, (neighbors, rank)) =>
                    val totalNeighbors = neighbors.size
                    neighbors.map(neighbor => (neighbor, rank/totalNeighbors))
            }

            // Calculate updated ranks
            val updatedRanks = contributions
                .reduceByKey(_ + _)
                .mapValues(sum => (1-d)/totalNodes + (d*sum))

            // Handle rank setting for nodes with no incoming links
            val allNodesRanks = sparkCtxt.parallelize(distinctNodes.toSeq)
                .map(node => (node, (1-d)/totalNodes))
                .leftOuterJoin(updatedRanks)
                .mapValues {
                    case (defaultRank, Some(calculatedRank)) => calculatedRank
                    case (defaultRank, None) => defaultRank
                }

            // Check for convergence after update
            val rankValChanges = ranks.join(allNodesRanks)
                .map { case (node, (oldRank, newRank)) => Math.abs(newRank - oldRank) }

            val maximumChange = rankValChanges.max()
            converged = maximumChange < tol

            ranks = allNodesRanks
            currItr = currItr + 1

            println(s"Curr Itr: $currItr, maximum Change: $maximumChange")
        }

        println(s"Convergence achieved after iteration: $currItr")

        // Output format conditions: sort by rank (desc), then by node (asce), keep 3 decimal places
        val finalResults = ranks
            .map {case (node, rank) => (node, BigDecimal(rank).setScale(3, BigDecimal.RoundingMode.HALF_UP).toDouble) } // Keeping 3 decimal places
            .sortBy(x => (-x._2, x._1)) //rank descending first (2), node ascending next (1)
            .map { case (node,rank) => s"$node,%.3f".format(rank) }

        // Move to HDFS Output file
        finalResults
            .coalesce(1)
            .saveAsTextFile(outputPath)

        sparkSion.stop()
    }
}