WITH sales_cte AS (
   SELECT
       ws.ws_order_number,
       sm.sm_carrier,
       ws.ws_ext_sales_price,
       wp.wp_rec_start_date
   FROM web_sales ws
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_rec_start_date >= DATE '2023-01-01'
),
returns_cte AS (
   SELECT
       wr.wr_order_number,
       r.r_reason_desc,
       wr.wr_return_amt_inc_tax
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
),
full_join_cte AS (
   SELECT
       s.ws_order_number,
       s.sm_carrier,
       s.ws_ext_sales_price,
       r.r_reason_desc,
       r.wr_return_amt_inc_tax
   FROM sales_cte s
   FULL OUTER JOIN returns_cte r
     ON s.ws_order_number = r.wr_order_number
)
SELECT
   COALESCE(category, 'ALL') AS category,
   metric_type,
   total_amount,
   ROUND(total_amount / gt.grand_total * 100, 2) AS pct_of_total,
   ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS rn
FROM (
   SELECT
       sm_carrier AS category,
       'sales' AS metric_type,
       SUM(ws_ext_sales_price) AS total_amount
   FROM full_join_cte
   WHERE ws_ext_sales_price IS NOT NULL
   GROUP BY ROLLUP (sm_carrier)
   UNION ALL
   SELECT
       r_reason_desc AS category,
       'returns' AS metric_type,
       SUM(wr_return_amt_inc_tax) AS total_amount
   FROM full_join_cte
   WHERE wr_return_amt_inc_tax IS NOT NULL
   GROUP BY ROLLUP (r_reason_desc)
) agg
CROSS JOIN (
   SELECT SUM(total_amount) AS grand_total FROM (
      SELECT SUM(ws_ext_sales_price) AS total_amount FROM sales_cte
      UNION ALL
      SELECT SUM(wr_return_amt_inc_tax) AS total_amount FROM returns_cte
   ) t
) gt
ORDER BY total_amount DESC
LIMIT 100
