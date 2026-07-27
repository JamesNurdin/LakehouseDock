/*
  Goal: Analyze web sales profitability by sold year, warehouse, and customer credit rating segment, 
  joining all five selected tables multiple times (including date dimensions for sold, ship, site open/close dates) 
  and using duplicate aliases for several tables to achieve at least nine join clauses. A CASE expression classifies customers, and an EXISTS sub‑query acts as a semi‑join filter. Results are ordered by total profit and limited to the top 100 rows.
*/
SELECT
  d_sold.d_year AS sold_year,
  wh_primary.w_warehouse_name,
  CASE
    WHEN cd_bill.cd_credit_rating = 'Good' THEN 'Preferred'
    ELSE 'Standard'
  END AS customer_segment,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_sales_price) AS avg_sales_price
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN web_site ws_site2
  ON ws.ws_web_site_sk = ws_site2.web_site_sk
JOIN warehouse wh_primary
  ON ws.ws_warehouse_sk = wh_primary.w_warehouse_sk
JOIN warehouse wh_secondary
  ON ws.ws_warehouse_sk = wh_secondary.w_warehouse_sk
JOIN date_dim d_open
  ON ws_site.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
  ON ws_site.web_close_date_sk = d_close.d_date_sk
WHERE EXISTS (
  SELECT 1
  FROM warehouse w_filter
  WHERE w_filter.w_warehouse_sk = ws.ws_warehouse_sk
    AND w_filter.w_gmt_offset > 0
)
  AND d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY
  d_sold.d_year,
  wh_primary.w_warehouse_name,
  CASE
    WHEN cd_bill.cd_credit_rating = 'Good' THEN 'Preferred'
    ELSE 'Standard'
  END
ORDER BY total_profit DESC
LIMIT 100
