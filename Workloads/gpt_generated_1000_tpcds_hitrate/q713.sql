WITH sales_union AS (
  SELECT
    cp.cp_department AS department,
    CASE WHEN ws.ws_coupon_amt > 1000 THEN 'high' ELSE 'low' END AS coupon_category,
    SUM(ws.ws_net_paid) AS total_ws_paid,
    SUM(ss.ss_net_paid) AS total_ss_paid,
    COUNT(*) AS txn_count,
    MAX(time.t_hour) AS max_hour
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim time ON cs.cs_sold_time_sk = time.t_time_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = time.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN store_sales ss ON ss.ss_sold_time_sk = time.t_time_sk
  JOIN store_returns sr ON sr.sr_return_time_sk = time.t_time_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN web_returns wr ON wr.wr_returned_time_sk = time.t_time_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cp.cp_catalog_number IN (1, 6, 12)
    AND cp.cp_type = 'catalog'
    AND cp.cp_catalog_number = (
      SELECT MIN(cp_catalog_number)
      FROM catalog_page
      WHERE cp_type = 'catalog'
    )
    AND sr.sr_return_tax > 10.00
    AND sr.sr_reversed_charge < 500.00
    AND ws.ws_coupon_amt BETWEEN 0 AND 5000
    AND time.t_hour BETWEEN 9 AND 17
    AND wp.wp_type = 'article'
  GROUP BY cp.cp_department,
    CASE WHEN ws.ws_coupon_amt > 1000 THEN 'high' ELSE 'low' END
  HAVING SUM(ws.ws_net_paid) > 10000

  UNION

  SELECT
    cp.cp_department AS department,
    CASE WHEN ws.ws_coupon_amt > 1000 THEN 'high' ELSE 'low' END AS coupon_category,
    SUM(ws.ws_net_paid) AS total_ws_paid,
    SUM(ss.ss_net_paid) AS total_ss_paid,
    COUNT(*) AS txn_count,
    MAX(time.t_hour) AS max_hour
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim time ON cs.cs_sold_time_sk = time.t_time_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = time.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN store_sales ss ON ss.ss_sold_time_sk = time.t_time_sk
  JOIN store_returns sr ON sr.sr_return_time_sk = time.t_time_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN web_returns wr ON wr.wr_returned_time_sk = time.t_time_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cp.cp_department = 'Electronics'
    AND ws.ws_coupon_amt > 2000
    AND time.t_hour >= 12
    AND wp.wp_type = 'article'
    AND EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_return_tax > 50
      LIMIT 1
    )
  GROUP BY cp.cp_department,
    CASE WHEN ws.ws_coupon_amt > 1000 THEN 'high' ELSE 'low' END
  HAVING COUNT(*) > 5
)
SELECT
  department,
  coupon_category,
  SUM(total_ws_paid) AS sum_ws_paid,
  SUM(total_ss_paid) AS sum_ss_paid,
  SUM(txn_count) AS total_txns,
  MAX(max_hour) AS latest_hour,
  CASE WHEN SUM(total_ws_paid) > 50000 THEN 'big' ELSE 'small' END AS size_flag
FROM sales_union
GROUP BY department, coupon_category
ORDER BY sum_ws_paid DESC
LIMIT 100
