WITH
date_filtered AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2000
),
store_agg AS (
    SELECT ss_customer_sk AS cust_sk,
           ss_sold_date_sk AS date_sk,
           SUM(ss_net_paid) AS store_sales,
           COUNT(*) AS store_txns
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk
),
web_agg AS (
    SELECT ws_bill_customer_sk AS cust_sk,
           ws_sold_date_sk AS date_sk,
           SUM(ws_net_paid) AS web_sales,
           COUNT(*) AS web_txns
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_sold_date_sk
),
catalog_agg AS (
    SELECT cs_bill_customer_sk AS cust_sk,
           cs_sold_date_sk AS date_sk,
           SUM(cs_net_paid) AS catalog_sales,
           COUNT(*) AS catalog_txns
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk, cs_sold_date_sk
),
customers_in_both AS (
    SELECT cust_sk FROM store_agg
    INTERSECT
    SELECT cust_sk FROM web_agg
),
all_sales AS (
    SELECT cust_sk, date_sk, store_sales, 0 AS web_sales, 0 AS catalog_sales,
           store_txns, 0 AS web_txns, 0 AS catalog_txns
    FROM store_agg
    UNION ALL
    SELECT cust_sk, date_sk, 0, web_sales, 0,
           0, web_txns, 0
    FROM web_agg
    UNION ALL
    SELECT cust_sk, date_sk, 0, 0, catalog_sales,
           0, 0, catalog_txns
    FROM catalog_agg
),
daily_sales AS (
    SELECT cust_sk, date_sk,
           SUM(store_sales) AS store_sales,
           SUM(web_sales) AS web_sales,
           SUM(catalog_sales) AS catalog_sales,
           SUM(store_txns) AS store_txns,
           SUM(web_txns) AS web_txns,
           SUM(catalog_txns) AS catalog_txns
    FROM all_sales
    GROUP BY cust_sk, date_sk
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_education_status,
           COALESCE(ca.ca_state, 'UNKNOWN') AS state
    FROM customer c
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_enriched AS (
    SELECT d.d_date,
           ci.c_customer_sk,
           CONCAT(ci.c_first_name, ' ', ci.c_last_name) AS full_name,
           ci.state,
           ci.cd_gender,
           ci.cd_education_status,
           ds.store_sales,
           ds.web_sales,
           ds.catalog_sales,
           ds.store_sales + ds.web_sales + ds.catalog_sales AS total_sales,
           ds.store_txns,
           ds.web_txns,
           ds.catalog_txns,
           ROW_NUMBER() OVER (PARTITION BY ci.c_customer_sk ORDER BY d.d_date DESC) AS rn,
           SUM(ds.store_sales + ds.web_sales + ds.catalog_sales) OVER (PARTITION BY ci.c_customer_sk ORDER BY d.d_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
           (SELECT AVG(inner_ds.store_sales + inner_ds.web_sales + inner_ds.catalog_sales)
            FROM daily_sales inner_ds
            WHERE inner_ds.cust_sk = ds.cust_sk) AS avg_daily_total
    FROM daily_sales ds
    JOIN date_filtered d
        ON ds.date_sk = d.d_date_sk
    JOIN customer_info ci
        ON ds.cust_sk = ci.c_customer_sk
    JOIN customers_in_both cib
        ON ds.cust_sk = cib.cust_sk
),
top5_per_customer AS (
    SELECT *
    FROM sales_enriched
    WHERE rn <= 5
),
with_prev AS (
    SELECT se.*,
           (SELECT total_sales
            FROM sales_enriched se2
            WHERE se2.c_customer_sk = se.c_customer_sk
              AND se2.d_date = date_add('day', -1, se.d_date)) AS prev_sales
    FROM top5_per_customer se
),
flagged AS (
    SELECT *,
           CASE
               WHEN prev_sales IS NULL OR prev_sales = 0 THEN NULL
               ELSE total_sales / prev_sales
           END AS growth_ratio,
           CASE
               WHEN prev_sales IS NOT NULL AND total_sales / prev_sales > 2 THEN 'Rapid Growth'
               WHEN prev_sales IS NOT NULL AND total_sales / prev_sales < 0.5 THEN 'Decline'
               ELSE 'Stable'
           END AS growth_status
    FROM with_prev
)
SELECT
    f.c_customer_sk,
    f.full_name,
    f.state,
    f.cd_gender,
    f.cd_education_status,
    f.d_date,
    round(f.total_sales, 2) AS cur_sales,
    round(COALESCE(f.prev_sales, 0), 2) AS prev_sales,
    round(f.growth_ratio, 2) AS growth_ratio,
    f.growth_status,
    round(f.avg_daily_total, 2) AS avg_daily_total,
    f.running_total
FROM flagged f
WHERE f.growth_status = 'Rapid Growth'
ORDER BY f.growth_ratio DESC
LIMIT 10
