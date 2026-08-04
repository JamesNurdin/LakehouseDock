WITH order_exceptions AS (
   SELECT ws_order_number AS order_number
   FROM web_sales
   EXCEPT
   SELECT cr_order_number
   FROM catalog_returns
),
unnested_sales AS (
   SELECT ws.ws_order_number,
          ws.ws_item_sk,
          ws.ws_quantity,
          ws.ws_sales_price,
          ARRAY[CAST(ws.ws_quantity AS DOUBLE), ws.ws_sales_price] AS metrics_arr
   FROM web_sales ws
),
unnested_metrics AS (
   SELECT us.ws_order_number,
          us.ws_item_sk,
          val AS metric_value
   FROM unnested_sales us
   CROSS JOIN UNNEST(us.metrics_arr) AS t(val)
)

SELECT
   d.d_year,
   d.d_month_seq,
   cp.cp_department,
   sm.sm_type,
   p.p_discount_active,
   COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
   SUM(ws.ws_net_paid) AS total_net_paid,
   SUM(cr.cr_return_amount) AS total_return_amount,
   SUM(sr.sr_return_amt) AS total_store_return_amt,
   SUM(wr.wr_return_amt) AS total_web_return_amt,
   AVG(um.metric_value) AS avg_metric_value
FROM date_dim d
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
FULL OUTER JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN order_exceptions oe ON ws.ws_order_number = oe.order_number
LEFT JOIN unnested_metrics um ON ws.ws_order_number = um.ws_order_number
WHERE
   d.d_year = 2001
   AND d.d_month_seq BETWEEN 1200 AND 1210
   AND cp.cp_department = 'Electronics'
   AND sm.sm_type = 'AIR'
   AND p.p_discount_active = 'Y'
   AND ws.ws_quantity > 5
GROUP BY
   d.d_year,
   d.d_month_seq,
   cp.cp_department,
   sm.sm_type,
   p.p_discount_active
HAVING SUM(ws.ws_net_paid) > 1000
ORDER BY d.d_year ASC, d.d_month_seq DESC
LIMIT 100
