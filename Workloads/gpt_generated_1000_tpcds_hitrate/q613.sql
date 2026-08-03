WITH sales_demo AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        cd.cd_dep_college_count
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_sales_price >= 2000
      AND cd.cd_purchase_estimate BETWEEN 5000 AND 9000
      AND cd.cd_dep_count >= 2
      AND cs.cs_bill_cdemo_sk IN (
          SELECT cs2.cs_bill_cdemo_sk
          FROM catalog_sales cs2
          WHERE cs2.cs_ext_wholesale_cost > 1500
          GROUP BY cs2.cs_bill_cdemo_sk
          HAVING COUNT(*) > 5
      )
)
SELECT
    sd.cd_gender,
    sd.cd_marital_status,
    bucket.bucket_name,
    SUM(sd.cs_net_profit) AS total_profit,
    AVG(sd.cs_net_profit) AS avg_profit,
    COUNT(*) AS sales_cnt,
    RANK() OVER (PARTITION BY bucket.bucket_name ORDER BY SUM(sd.cs_net_profit) DESC) AS profit_rank,
    CASE WHEN SUM(sd.cs_net_profit) > 50000 THEN 'High' ELSE 'Medium' END AS profit_category
FROM sales_demo sd
CROSS JOIN (VALUES ROW('A'), ROW('B')) AS bucket(bucket_name)
GROUP BY sd.cd_gender, sd.cd_marital_status, bucket.bucket_name
HAVING AVG(sd.cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
