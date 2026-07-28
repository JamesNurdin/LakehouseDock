WITH ws_agg AS (
    SELECT
        ws_warehouse_sk AS warehouse_sk,
        ws_sold_time_sk AS time_sk,
        ws_web_page_sk AS web_page_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450500
      AND ws_quantity > 0
      AND ws_wholesale_cost > 0
      AND ws_ext_discount_amt < 100
      AND ws_ext_tax IS NOT NULL
    GROUP BY ws_warehouse_sk, ws_sold_time_sk, ws_web_page_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    t.t_hour,
    wp.wp_type,
    a.total_sales,
    a.total_tax,
    a.sales_cnt,
    CASE WHEN cr.cr_refunded_cash > 500 THEN 'High' ELSE 'Low' END AS refund_level,
    (SELECT AVG(total_sales) FROM ws_agg) AS avg_sales_all,
    RANK() OVER (PARTITION BY w.w_state ORDER BY a.total_sales DESC) AS sales_rank_state
FROM ws_agg a
JOIN warehouse w ON a.warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON a.time_sk = t.t_time_sk
JOIN web_page wp ON a.web_page_sk = wp.wp_web_page_sk
LEFT JOIN catalog_returns cr 
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
   AND cr.cr_return_quantity > 0
WHERE w.w_city = 'Seattle'
  AND w.w_state = 'CA'
  AND t.t_hour BETWEEN 8 AND 17
  AND wp.wp_type = 'content'
  AND a.total_sales > 1000
ORDER BY sales_rank_state, w.w_warehouse_id
