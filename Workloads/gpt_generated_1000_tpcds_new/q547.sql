WITH
sales_base AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_warehouse_sk,
       cs.cs_item_sk,
       ARRAY[CAST(cs.cs_quantity AS decimal(12,2)), cs.cs_net_profit] AS metric_arr
   FROM catalog_sales cs
),
sales_with_cnt AS (
   SELECT
       sb.cs_sold_date_sk,
       sb.cs_warehouse_sk,
       sb.cs_item_sk,
       sb.metric_arr,
       lc.item_cnt
   FROM sales_base sb
   CROSS JOIN LATERAL (
        SELECT COUNT(*) AS item_cnt
        FROM catalog_sales cs3
        WHERE cs3.cs_item_sk = sb.cs_item_sk
   ) lc
   WHERE lc.item_cnt > 10
),
sales_metrics AS (
   SELECT
       d.d_year AS year,
       w.w_warehouse_name AS category,
       CASE u.metric_idx WHEN 1 THEN 'Quantity' ELSE 'NetProfit' END AS metric_name,
       SUM(u.metric_val) AS metric_value
   FROM sales_with_cnt s
   JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
   CROSS JOIN UNNEST(s.metric_arr) WITH ORDINALITY AS u(metric_val, metric_idx)
   GROUP BY d.d_year, w.w_warehouse_name, u.metric_idx
),
returns_metrics AS (
   SELECT
       d.d_year AS year,
       cd.cd_gender AS category,
       'ReturnLoss' AS metric_name,
       SUM(wr.wr_net_loss) AS metric_value
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
   WHERE EXISTS (
       SELECT 1
       FROM catalog_sales cs
       WHERE cs.cs_order_number = wr.wr_order_number
         AND cs.cs_sold_date_sk = d.d_date_sk
   )
   GROUP BY d.d_year, cd.cd_gender
),
full_joined AS (
   SELECT
       COALESCE(s.year, r.year) AS year,
       COALESCE(s.category, r.category) AS category,
       COALESCE(s.metric_name, r.metric_name) AS metric_name,
       COALESCE(s.metric_value, r.metric_value) AS metric_value
   FROM sales_metrics s
   FULL OUTER JOIN returns_metrics r
        ON s.year = r.year AND s.category = r.category
)
SELECT DISTINCT year, category, metric_name, metric_value
FROM full_joined
WHERE metric_value IS NOT NULL

UNION

SELECT year, category, metric_name, metric_value
FROM (
   SELECT
       d.d_year AS year,
       'ALL' AS category,
       'OverallSales' AS metric_name,
       SUM(cs.cs_ext_sales_price) AS metric_value
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY d.d_year
) overall
WHERE metric_value > 0
LIMIT 100
