#!/bin/bash

# test_hdfs.sh
function test_hdfs_q1() {
    docker compose -f cs511p1-compose.yaml exec main hdfs dfsadmin -report >&2
}

function test_hdfs_q2() {
    docker compose -f cs511p1-compose.yaml cp resources/fox.txt main:/test_fox.txt
    docker compose -f cs511p1-compose.yaml exec main bash -x -c '\
        hdfs dfs -mkdir -p /test; \
        hdfs dfs -put -f /test_fox.txt /test/fox.txt; \
        hdfs dfs -cat /test/fox.txt'
}

function test_hdfs_q3() {
    docker compose -f cs511p1-compose.yaml exec main bash -x -c '\
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op create -threads 100 -files 10000; \
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op open -threads 100 -files 10000; \
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op delete -threads 100 -files 10000; \
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op rename -threads 100 -files 10000'
}

function test_hdfs_q4() {
    docker compose -f cs511p1-compose.yaml cp resources/hadoop-terasort-3.3.6.jar \
    main:/hadoop-terasort-3.3.6.jar
docker compose -f cs511p1-compose.yaml exec main bash -x -c '\
    hdfs dfs -rm -r -f tera-in tera-out tera-val; \
    hadoop jar /hadoop-terasort-3.3.6.jar teragen 1000000 tera-in; \
    hadoop jar /hadoop-terasort-3.3.6.jar terasort tera-in tera-out; \
    hadoop jar /hadoop-terasort-3.3.6.jar teravalidate tera-out tera-val; \
    hdfs dfs -cat tera-val/*;'
}

# test_spark.sh
function test_spark_q1() {
    docker compose -f cs511p1-compose.yaml cp resources/active_executors.scala \
        main:/active_executors.scala
    docker compose -f cs511p1-compose.yaml exec main bash -x -c '\
        cat /active_executors.scala | spark-shell --master spark://main:7077'
}

function test_spark_q2() {
    docker compose -f cs511p1-compose.yaml cp resources/pi.scala main:/pi.scala
    docker compose -f cs511p1-compose.yaml exec main bash -x -c '\
        cat /pi.scala | spark-shell --master spark://main:7077'

}

function test_spark_q3() {
    docker compose -f cs511p1-compose.yaml cp resources/fox.txt main:/test_fox.txt
    docker compose -f cs511p1-compose.yaml exec main bash -x -c '\
        hdfs dfs -mkdir -p /test; \
        hdfs dfs -put -f /test_fox.txt /test/fox.txt; \
        hdfs dfs -cat /test/fox.txt'
    docker compose -f cs511p1-compose.yaml exec main bash -x -c '\
        echo "sc.textFile(\"hdfs://main:9000/test/fox.txt\").collect()" | \
        spark-shell --master spark://main:7077'

}

function test_spark_q4() {
    docker compose -f cs511p1-compose.yaml cp resources/spark-terasort-1.2.jar \
        main:/spark-terasort-1.2.jar
    docker compose -f cs511p1-compose.yaml exec main spark-submit \
        --master spark://main:7077 \
        --class com.github.ehiggs.spark.terasort.TeraGen local:///spark-terasort-1.2.jar \
        100m hdfs://main:9000/spark/tera-in
    docker compose -f cs511p1-compose.yaml exec main spark-submit \
        --master spark://main:7077 \
        --class com.github.ehiggs.spark.terasort.TeraSort local:///spark-terasort-1.2.jar \
        hdfs://main:9000/spark/tera-in hdfs://main:9000/spark/tera-out
    docker compose -f cs511p1-compose.yaml exec main spark-submit \
        --master spark://main:7077 \
        --class com.github.ehiggs.spark.terasort.TeraValidate local:///spark-terasort-1.2.jar \
        hdfs://main:9000/spark/tera-out hdfs://main:9000/spark/tera-val
}

function test_terasorting() {

    # Step 1: Copy csv into hdfs
    docker compose -f cs511p1-compose.yaml cp scala_sorting/terasorting_test.csv main:/input.csv >/dev/null 2>&1

    # Step 2: Upload the csv to hdfs
    docker compose -f cs511p1-compose.yaml exec main bash -c '\
        hdfs dfs -rm -r -f /sorting/input /sorting/output; \
        hdfs dfs -mkdir -p /sorting/input; \
        hdfs dfs -put -f /input.csv /sorting/input/inputCaps.csv
    ' >/dev/null 2>&1

    # Step 3: Run Spark job using the Class created with input & output
    docker compose -f cs511p1-compose.yaml exec main bash -c '\
        spark-submit \
        --class TeraSortByCaps \
        --master spark://main:7077 \
        /opt/sorting/target/scala-2.12/terasortingbyyearcap_2.12-1.0.jar \
        hdfs://main:9000/sorting/input \
        hdfs://main:9000/sorting/output
    ' >/dev/null 2>&1

    # Step 4: Merge the HDFS output to a single csv and store it in a temp directory
    docker compose -f cs511p1-compose.yaml exec main bash -c '\
        hdfs dfs -getmerge /sorting/output /tmp/sorted_caps.csv
    ' >/dev/null 2>&1

    # Step 5: Copy CSV from docker to local
    docker compose -f cs511p1-compose.yaml cp main:/tmp/sorted_caps.csv out/terasorting_out.csv >/dev/null 2>&1

    # Step 6: Print the CSV to stdout for .out file testing
    cat out/terasorting_out.csv

    # Step 7: Delete local temporary CSV
    rm -f out/terasorting_out.csv
}

function test_pagerank() {
    # Step 1: Copy csv into hdfs
    docker compose -f cs511p1-compose.yaml cp pagerank_sorting/pagerank_test.csv main:/graph_input.csv >/dev/null 2>&1

    # Step 2: Upload the csv to hdfs
    docker compose -f cs511p1-compose.yaml exec main bash -c '\
      hdfs dfs -rm -r -f /pagerank/input /pagerank/output; \
      hdfs dfs -mkdir -p /pagerank/input; \
      hdfs dfs -put -f /graph_input.csv /pagerank/input/graph.csv
    ' >/dev/null 2>&1

    # Step 3: Run Spark job using the Class created for PageRank with input & output
    docker compose -f cs511p1-compose.yaml exec main bash -c '\
      spark-submit \
      --class PageRankImplementation \
      --master spark://main:7077 \
      --driver-memory 1g \
      --executor-memory 1g \
      /opt/pagerank/target/scala-2.12/pagerankimplementation_2.12-1.0.jar \
      hdfs://main:9000/pagerank/input \
      hdfs://main:9000/pagerank/output
    ' >/dev/null 2>&1

    # Step 4: Merge the HDFS output to a single csv and store it in a temp directory
    docker compose -f cs511p1-compose.yaml exec main bash -c '\
        hdfs dfs -getmerge /pagerank/output /tmp/pagerank_test.csv
    ' >/dev/null 2>&1

    # Step 5: Copy CSV from docker to local
    docker compose -f cs511p1-compose.yaml cp main:/tmp/pagerank_test.csv out/pagerank_output.csv >/dev/null 2>&1

    # Step 6: Print the CSV to stdout for .out file testing
    cat out/pagerank_output.csv

    # Step 7: Delete local temporary CSV
    rm -f out/pagerank_output.csv
}

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p out

total_score=0;

echo -n "Testing HDFS Q1 ..."
test_hdfs_q1 > out/test_hdfs_q1.out 2>&1
if grep -q "Live datanodes (3)" out/test_hdfs_q1.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing HDFS Q2 ..."
test_hdfs_q2 > out/test_hdfs_q2.out 2>&1
if grep -E -q '^The quick brown fox jumps over the lazy dog[[:space:]]*$' out/test_hdfs_q2.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing HDFS Q3 ..."
test_hdfs_q3 > out/test_hdfs_q3.out 2>&1
if [ "$(grep -E '# operations: 10000[[:space:]]*$' out/test_hdfs_q3.out | wc -l)" -eq 4 ]; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing HDFS Q4 ..."
test_hdfs_q4 > out/test_hdfs_q4.out 2>&1
if [ "$(grep -E 'Job ([[:alnum:]]|_)+ completed successfully[[:space:]]*$' out/test_hdfs_q4.out | wc -l)" -eq 3 ] && grep -q "7a27e2d0d55de" out/test_hdfs_q4.out; then
    echo -e " ${GREEN}PASS${NC}";
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Spark Q1 ..."
test_spark_q1 > out/test_spark_q1.out 2>&1
if grep -E -q "Seq\[String\] = List\([0-9\.:]*, [0-9\.:]*, [0-9\.:]*\)" out/test_spark_q1.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Spark Q2 ..."
test_spark_q2 > out/test_spark_q2.out 2>&1
if grep -E -q '^Pi is roughly 3.14[0-9]*' out/test_spark_q2.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Spark Q3 ..."
test_spark_q3 > out/test_spark_q3.out 2>&1
if grep -q 'Array(The quick brown fox jumps over the lazy dog)' out/test_spark_q3.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Spark Q4 ..."
test_spark_q4 > out/test_spark_q4.out 2>&1
if grep -E -q "^Number of records written: 1000000[[:space:]]*$" out/test_spark_q4.out && \
   grep -q "==== TeraSort took .* ====" out/test_spark_q4.out && \
   grep -q "7a30469d6f066" out/test_spark_q4.out && \
   grep -q "partitions are properly sorted" out/test_spark_q4.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Tera Sorting ..."
test_terasorting > out/test_terasorting.out 2>&1
if diff --strip-trailing-cr resources/example-terasorting.truth out/test_terasorting.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=20 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing PageRank (extra credit) ..."
test_pagerank > out/test_pagerank.out 2>&1
if diff --strip-trailing-cr resources/example-pagerank.truth out/test_pagerank.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=20 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo "-----------------------------------";
echo "Total Points/Full Points: ${total_score}/120";