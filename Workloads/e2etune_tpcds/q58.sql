WITH catalog_agg AS (
    SELECT cs_sold_date_sk,
           cs_call_center_sk,
           SUM(cs_net_paid_inc_tax) AS catalog_sales,
           SUM(cs_quantity) AS catalog_quantity
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2450845
    GROUP BY cs_sold_date_sk, cs_call_center_sk
),
store_agg AS (
    SELECT ss_sold_date_sk,
           SUM(ss_net_paid_inc_tax) AS store_sales,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2450845
    GROUP BY ss_sold_date_sk
),
web_agg AS (
    SELECT ws_sold_date_sk,
           SUM(ws_net_paid_inc_tax) AS web_sales,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2450845
    GROUP BY ws_sold_date_sk
)
SELECT c.cc_division_name,
       cat.cs_sold_date_sk AS sales_date,
       cat.catalog_sales,
       COALESCE(st.store_sales, 0) AS store_sales,
       COALESCE(wb.web_sales, 0) AS web_sales,
       (cat.catalog_sales + COALESCE(st.store_sales, 0) + COALESCE(wb.web_sales, 0)) AS total_sales,
       RANK() OVER (PARTITION BY cat.cs_sold_date_sk ORDER BY (cat.catalog_sales + COALESCE(st.store_sales, 0) + COALESCE(wb.web_sales, 0)) DESC) AS sales_rank
FROM call_center c
JOIN catalog_agg cat ON c.cc_call_center_sk = cat.cs_call_center_sk
LEFT JOIN store_agg st ON cat.cs_sold_date_sk = st.ss_sold_date_sk
LEFT JOIN web_agg wb ON cat.cs_sold_date_sk = wb.ws_sold_date_sk
WHERE c.cc_manager = 'Bob Belcher'
ORDER BY cat.cs_sold_date_sk, total_sales DESC
LIMIT 50
