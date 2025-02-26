CREATE DATABASE web_logs;
USE web_logs;
CREATE EXTERNAL TABLE web_server_logs (
    ip STRING,
    timestamp_ STRING,
    url STRING,
    status INT,
    user_agent STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/web_logs/';
LOAD DATA INPATH '/user/hive/warehouse/web_logs/web_server_logs.csv' INTO TABLE web_server_logs;
SELECT COUNT(*) AS total_requests FROM web_server_logs;
SELECT status, COUNT(*) AS count FROM web_server_logs GROUP BY status;
SELECT url, COUNT(*) AS visits FROM web_server_logs GROUP BY url ORDER BY visits DESC LIMIT 3;
SELECT user_agent, COUNT(*) AS count FROM web_server_logs GROUP BY user_agent ORDER BY count DESC;
SELECT ip, COUNT(*) AS failed_requests 
FROM web_server_logs 
WHERE status IN (404, 500) 
GROUP BY ip 
HAVING COUNT(*) > 3;
SELECT SUBSTR(timestamp_, 1, 16) AS time_slot, COUNT(*) AS request_count 
FROM web_server_logs 
GROUP BY SUBSTR(timestamp_, 1, 16) 
ORDER BY time_slot;
CREATE TABLE web_server_logs_partitioned (
    ip STRING,
    timestamp_ STRING,
    url STRING,
    user_agent STRING
) PARTITIONED BY (status INT)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

INSERT INTO TABLE web_server_logs_partitioned PARTITION (status)
SELECT ip, timestamp_, url, user_agent, status FROM web_server_logs;
DESCRIBE web_server_logs;
INSERT OVERWRITE DIRECTORY '/user/hive/output/web_logs_analysis' 
SELECT * FROM web_server_logs;