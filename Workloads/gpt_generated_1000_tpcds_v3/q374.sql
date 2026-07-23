WITH catalog_agg AS (
    SELECT w.w_warehouse_id AS location_id,
           'Warehouse' AS location_type,
           SUM(cs.cs_net_profit) AS total_net_amount
    FROM catalog_sales cs
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND w.w_gmt_offset = -5.00
    GROUP BY w.w_warehouse_id
),
store_agg AS (
    SELECT CAST(ss.ss_store_sk AS VARCHAR) AS location_id,
           'Store' AS location_type,
           SUM(ss.ss_net_profit) AS total_net_amount
    FROM store_sales ss
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND c.c_birth_year >= 1950
    GROUP BY CAST(ss.ss_store_sk AS VARCHAR)
)
SELECT location_id,
       location_type,
       total_net_amount
FROM (
    SELECT location_id, location_type, total_net_amount FROM catalog_agg
    UNION ALL
    SELECT location_id, location_type, total_net_amount FROM store_agg
) AS combined
ORDER BY total_net_amount DESC
LIMIT 100
