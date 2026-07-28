SELECT
    s.s_store_name,
    i.i_product_name,
    ws_site.web_name,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_cnt,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store
  ON s.s_closed_date_sk = d_store.d_date_sk
JOIN customer_address ca_wr_refund
  ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_returning
  ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN customer_address ca_cr_refund
  ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
JOIN customer_address ca_cr_returning
  ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
WHERE d_sold.d_year = 2001
  AND i.i_category = 'Sports'
  AND sm.sm_type = 'AIR'
  AND ws.ws_net_paid > 5000
  AND ws.ws_quantity BETWEEN 2 AND 10
  AND wr.wr_fee > 50
  AND cr.cr_return_amount > 100
GROUP BY s.s_store_name, i.i_product_name, ws_site.web_name
ORDER BY total_profit DESC
LIMIT 100
