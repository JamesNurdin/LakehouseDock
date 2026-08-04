WITH ws_summary AS (
   SELECT
      ws.ws_sold_date_sk,
      d.d_year,
      ws.ws_item_sk,
      i.i_category,
      ws.ws_quantity,
      ws.ws_sales_price,
      ARRAY[ws.ws_quantity, CAST(ws.ws_sales_price AS double)] AS qty_price_arr
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
),
ws_unnested AS (
   SELECT
      ws_sold_date_sk,
      d_year,
      ws_item_sk,
      i_category,
      metric_value,
      CASE WHEN metric_value = ws_quantity THEN 'quantity' ELSE 'price' END AS metric_type
   FROM ws_summary
   CROSS JOIN UNNEST(qty_price_arr) AS t(metric_value)
)
SELECT
   d_year,
   i_category,
   metric_type,
   SUM(metric_value) AS total_metric
FROM ws_unnested
WHERE EXISTS (
   SELECT 1
   FROM store_returns sr
   WHERE sr.sr_item_sk = ws_unnested.ws_item_sk
     AND sr.sr_return_quantity > 0
)
GROUP BY d_year, i_category, metric_type

UNION DISTINCT

SELECT
   COALESCE(d1.d_year, d2.d_year) AS d_year,
   i.i_category,
   CASE WHEN sr.sr_return_quantity IS NULL THEN 'sale' ELSE 'return' END AS metric_type,
   SUM(COALESCE(ss.ss_ext_sales_price, 0) - COALESCE(sr.sr_return_amt, 0)) AS total_metric
FROM store_sales ss
FULL OUTER JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
LEFT JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
LEFT JOIN item i ON COALESCE(ss.ss_item_sk, sr.sr_item_sk) = i.i_item_sk
WHERE COALESCE(d1.d_year, d2.d_year) = 2001
GROUP BY
   COALESCE(d1.d_year, d2.d_year),
   i.i_category,
   CASE WHEN sr.sr_return_quantity IS NULL THEN 'sale' ELSE 'return' END

ORDER BY d_year, i_category, metric_type, total_metric DESC
LIMIT 100
