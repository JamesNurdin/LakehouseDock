WITH
  filtered_dates AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1 AND 12
  ),
  inventory_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  returns_join AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_net_loss,
      wr.wr_web_page_sk,
      d.d_date,
      t.t_hour,
      t.t_minute,
      wp.wp_url,
      cc.cc_name,
      ws.web_name,
      p.p_promo_name
    FROM web_returns wr
    JOIN filtered_dates d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk OR p.p_end_date_sk = d.d_date_sk
    WHERE t.t_shift = 'first'
      AND wp.wp_type = 'Content'
  ),
  high_returns AS (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_amt > 500
      AND wr_returned_date_sk IN (SELECT d_date_sk FROM filtered_dates)
  ),
  promo_orders AS (
    SELECT wr.wr_order_number
    FROM web_returns wr
    JOIN promotion p ON p.p_start_date_sk = wr.wr_returned_date_sk
    WHERE p.p_discount_active = 'Y'
  ),
  intersect_orders AS (
    SELECT hr.wr_order_number
    FROM high_returns hr
    INTERSECT
    SELECT po.wr_order_number
    FROM promo_orders po
  )
SELECT
  rj.d_date,
  rj.t_hour,
  rj.t_minute,
  rj.wp_url,
  rj.cc_name,
  rj.web_name,
  rj.p_promo_name,
  rj.wr_return_amt,
  rj.wr_net_loss,
  SUM(rj.wr_return_amt) OVER (PARTITION BY rj.d_date ORDER BY rj.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt,
  RANK() OVER (PARTITION BY rj.d_date ORDER BY rj.wr_return_amt DESC) AS return_rank,
  (SELECT COUNT(*) FROM inventory_sample i3 WHERE i3.inv_date_sk = d.d_date_sk) AS sample_inventory_count,
  CASE
    WHEN rj.wr_return_amt > 1000 THEN 'Large'
    WHEN rj.wr_return_amt > 500 THEN 'Medium'
    ELSE 'Small'
  END AS size_category
FROM returns_join rj
JOIN date_dim d ON rj.wr_returned_date_sk = d.d_date_sk
WHERE rj.wr_order_number IN (SELECT wr_order_number FROM intersect_orders)
UNION
SELECT
  d.d_date,
  NULL AS t_hour,
  NULL AS t_minute,
  NULL AS wp_url,
  NULL AS cc_name,
  ws.web_name,
  NULL AS p_promo_name,
  NULL AS wr_return_amt,
  NULL AS wr_net_loss,
  NULL AS cumulative_return_amt,
  NULL AS return_rank,
  (SELECT SUM(i4.inv_quantity_on_hand) FROM inventory i4 WHERE i4.inv_date_sk = d.d_date_sk) AS total_inventory,
  'No Return' AS size_category
FROM web_site ws
JOIN filtered_dates d ON ws.web_open_date_sk = d.d_date_sk
WHERE ws.web_state = 'TX'
  AND d.d_month_seq = 5
ORDER BY d_date DESC, return_rank
LIMIT 100
