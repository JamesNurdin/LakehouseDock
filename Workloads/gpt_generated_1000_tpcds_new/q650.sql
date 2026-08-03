/*
Goal: Identify stores that recorded sales in 2001 but had no returns in the same year, break down sales and tax amounts per store, and provide an overall total row.
*/
WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_sales_price,
        ss.ss_ext_tax,
        ARRAY[ss.ss_sales_price, ss.ss_ext_tax] AS price_tax_array
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_item_sk = ss.ss_item_sk
            AND p.p_start_date_sk = ss.ss_sold_date_sk
      )
),
expanded_sales AS (
    SELECT
        sd.ss_store_sk,
        sd.s_store_name,
        val AS metric_value,
        CASE WHEN val = sd.ss_sales_price THEN 'sales_price' ELSE 'ext_tax' END AS metric_type
    FROM sales_data sd
    CROSS JOIN UNNEST(sd.price_tax_array) AS t(val)
),
sales_store_keys AS (
    SELECT DISTINCT ss.ss_store_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
return_store_keys AS (
    SELECT DISTINCT sr.sr_store_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
sales_only_keys AS (
    SELECT ss_store_sk FROM sales_store_keys
    EXCEPT
    SELECT sr_store_sk FROM return_store_keys
),
sales_summary AS (
    SELECT
        s.s_store_name,
        es.metric_type,
        SUM(es.metric_value) AS total_metric
    FROM sales_only_keys sok
    JOIN store s ON sok.ss_store_sk = s.s_store_sk
    JOIN expanded_sales es ON s.s_store_sk = es.ss_store_sk
    GROUP BY s.s_store_name, es.metric_type
),
total_row AS (
    SELECT
        'ALL_STORES' AS s_store_name,
        SUM(total_metric) AS total_metric
    FROM sales_summary
)
SELECT s_store_name,
       metric_type,
       total_metric
FROM sales_summary
UNION ALL
SELECT s_store_name,
       'overall' AS metric_type,
       total_metric
FROM total_row
ORDER BY s_store_name, metric_type
