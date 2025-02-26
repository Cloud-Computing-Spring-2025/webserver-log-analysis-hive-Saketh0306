# Web-Server-Log-Analysis
# Web Server Log Analysis with Apache Hive

## Project Overview
This project analyzes web server log data using Apache Hive. The dataset consists of web requests with fields such as IP address, timestamp, requested URL, HTTP status code, and user agent. The goal is to extract meaningful insights from the log data, optimize query performance using partitioning, and export results for further analysis.

## Implementation Approach

### 1. **Database and Table Setup**
- Created a Hive database `web_logs`.
- Defined an **external** table `web_server_logs` to store log data.
- Partitioned the data by HTTP status code to improve query performance.

### 2. **Data Loading**
- Uploaded the CSV file containing log data into HDFS.
- Loaded the data into the Hive table using `LOAD DATA INPATH`.

### 3. **Analysis Queries**
- **Total Web Requests:** Counts all log entries.
- **HTTP Status Code Frequency:** Aggregates request counts for each status code.
- **Most Visited Pages:** Identifies the top 3 most frequently accessed URLs.
- **Traffic Source Analysis:** Determines the most common user agents (browsers).
- **Suspicious Activity Detection:** Lists IP addresses with more than 3 failed requests (status 404 or 500).
- **Traffic Trends Over Time:** Groups requests by timestamp to observe traffic patterns.

### 4. **Partitioning Implementation**
- Created a **partitioned table `web_server_logs_partitioned`** using `status` as the partition column.
- Inserted data dynamically using `SET hive.exec.dynamic.partition.mode = nonstrict`.

### 5. **Exporting Results**
- Used `INSERT OVERWRITE DIRECTORY` to export the results into an HDFS directory.

## Execution Steps
### 1. **Setup Hive Environment**
```sql
CREATE DATABASE IF NOT EXISTS web_logs;
USE web_logs;
```

### 2. **Create External Table**
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS web_server_logs (
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
```

### 3. **Load Data into Hive**
```sql
LOAD DATA INPATH '/user/hive/warehouse/web_logs/web_server_logs.csv' INTO TABLE web_server_logs;
```

### 4. **Run Analysis Queries**
```sql
-- Total Web Requests
SELECT COUNT(*) AS total_requests FROM web_server_logs;

-- HTTP Status Code Frequency
SELECT status, COUNT(*) AS count FROM web_server_logs GROUP BY status;

-- Most Visited Pages
SELECT url, COUNT(*) AS visits
FROM web_server_logs
GROUP BY url
ORDER BY visits DESC
LIMIT 3;

-- Traffic Source Analysis
SELECT user_agent, COUNT(*) AS count
FROM web_server_logs
GROUP BY user_agent
ORDER BY count DESC;

-- Suspicious IP Addresses
SELECT ip, COUNT(*) AS failed_requests
FROM web_server_logs
WHERE status IN (404, 500)
GROUP BY ip
HAVING COUNT(*) > 3;

-- Traffic Trends Over Time
SELECT SUBSTR(timestamp_, 1, 16) AS time_slot, COUNT(*) AS request_count
FROM web_server_logs
GROUP BY SUBSTR(timestamp_, 1, 16)
ORDER BY time_slot;
```

### 5. **Implement Partitioning**
```sql
CREATE TABLE IF NOT EXISTS web_server_logs_partitioned (
    ip STRING,
    timestamp_ STRING,
    url STRING,
    user_agent STRING
) PARTITIONED BY (status INT)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Enable Dynamic Partitioning
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

-- Insert Data into Partitioned Table
INSERT INTO TABLE web_server_logs_partitioned PARTITION (status)
SELECT ip, timestamp_, url, user_agent, status FROM web_server_logs;
```

### 6. **Export Analysis Results**
```sql
INSERT OVERWRITE DIRECTORY '/user/hive/output/web_logs_analysis'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
SELECT * FROM web_server_logs;
```

## Challenges Faced & Resolutions
1. **Dynamic Partitioning Error**: Resolved by enabling dynamic partitioning and setting `hive.exec.dynamic.partition.mode = nonstrict`.
2. **CSV Parsing Issues**: Ensured correct field delimiters and validated data format before loading.
3. **Performance Optimization**: Used partitioning to speed up queries on `status` column.

## Sample Input (CSV Format)
```csv
ip,timestamp,url,status,user_agent
192.168.1.1,2024-02-01 10:15:00,/home,200,Mozilla/5.0
192.168.1.2,2024-02-01 10:16:00,/products,200,Chrome/90.0
192.168.1.3,2024-02-01 10:17:00,/checkout,404,Safari/13.1
192.168.1.10,2024-02-01 10:18:00,/home,500,Mozilla/5.0
192.168.1.15,2024-02-01 10:19:00,/products,404,Chrome/90.0
```

## Expected Output
### **Total Web Requests**
```
Total Requests: 100
```
### **Status Code Analysis**
```
200: 80
404: 10
500: 10
```
### **Most Visited Pages**
```
/home: 50
/products: 30
/checkout: 20
```
### **Traffic Source Analysis**
```
Mozilla/5.0: 60
Chrome/90.0: 30
Safari/13.1: 10
```
### **Suspicious IP Addresses**
```
192.168.1.10: 5 failed requests
192.168.1.15: 4 failed requests
```
### **Traffic Trends Over Time**
```
2024-02-01 10:15: 5 requests
2024-02-01 10:16: 7 requests
```

