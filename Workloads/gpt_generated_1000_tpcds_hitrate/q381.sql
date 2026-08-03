WITH
  filtered_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_sales_price,
      ws.ws_net_profit,
      ws.ws_bill_customer_sk,
      ws.ws_promo_sk,
      ws.ws_warehouse_sk,
      ws.ws_web_page_sk
    FROM
      web_sales ws
      JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE
      d.d_year = 2001
      AND ws.ws_sales_price > 100.00
      AND ws.ws_quantity <= 5
      AND t.t_hour BETWEEN 9 AND 17
  ),
  orders_without_returns AS (
    SELECT
      ws_order_number AS order_number
    FROM
      filtered_sales
    EXCEPT
    SELECT
      wr_order_number AS order_number
    FROM
      web_returns
  )
SELECT
  d.d_year,
  p.p_promo_name,
  w.w_warehouse_name,
  wp.wp_type,
  SUM(fs.ws_quantity) AS total_quantity,
  AVG(fs.ws_sales_price) AS avg_sales_price,
  COUNT(DISTINCT fs.ws_order_number) AS distinct_order_cnt,
  CASE
    WHEN SUM(fs.ws_net_profit) > 0 THEN 'PROFIT'
    ELSE 'LOSS'
  END AS profit_flag,
  -- scalar sub‑query used in projection
  (SELECT AVG(ws_net_profit) FROM filtered_sales) AS overall_avg_profit
FROM
  filtered_sales fs
  JOIN orders_without_returns owr ON fs.ws_order_number = owr.order_number
  JOIN date_dim d ON fs.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON fs.ws_sold_time_sk = t.t_time_sk
  JOIN promotion p ON fs.ws_promo_sk = p.p_promo_sk
  JOIN warehouse w ON fs.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON fs.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer c ON fs.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
                      AND i.inv_date_sk = d.d_date_sk
  LEFT JOIN reason r ON r.r_reason_sk = COALESCE(cr.cr_reason_sk, sr.sr_reason_sk, wr.wr_reason_sk)
  LEFT JOIN store s ON s.s_store_sk = sr.sr_store_sk
  LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
WHERE
  d.d_month_seq BETWEEN 1 AND 12
GROUP BY
  d.d_year,
  p.p_promo_name,
  w.w_warehouse_name,
  wp.wp_type,
  d.d_year,
  p.p_promo_name,
  w.w_warehouse_name,
  wp.wp_type
HAVING
  COUNT(*) > 10
ORDER BY
  total_quantity DESC
LIMIT 100
