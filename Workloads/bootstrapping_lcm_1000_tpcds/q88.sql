SELECT
  s.s_store_id,
  s.s_city,
  s.s_state,
  d.d_year,
  COUNT(DISTINCT cr.cr_order_number) AS num_returns,
  SUM(cr.cr_net_loss) AS total_return_loss,
  AVG(cr.cr_return_quantity) AS avg_return_qty,
  COUNT(DISTINCT ws.ws_order_number) AS num_web_sales,
  SUM(ws.ws_ext_sales_price) AS total_sales_amount,
  SUM(ws.ws_net_profit) AS total_net_profit,
  CASE
    WHEN SUM(ws.ws_net_profit) = 0 THEN NULL
    ELSE SUM(cr.cr_net_loss) / SUM(ws.ws_net_profit)
  END AS loss_to_profit_ratio,
  MIN(d.d_date) AS min_date,
  MAX(d.d_date) AS max_date,
  COUNT(DISTINCT ca_refund.ca_city) AS distinct_refunded_cities,
  AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d.d_year) AS year_seq_by_store
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_ship_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
  ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'TX'
  AND ca_refund.ca_country = 'United States'
GROUP BY
  s.s_store_id,
  s.s_city,
  s.s_state,
  d.d_year
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
