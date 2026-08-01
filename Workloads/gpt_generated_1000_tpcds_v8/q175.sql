WITH
  -- Filter the date dimension for the year 2001
  d AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
  ),
  -- Separate alias for the ship‑date of a web sale (also linked to date_dim)
  d_ship AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
  )
SELECT
  COALESCE(s.s_store_name, 'All Stores')          AS store_name,
  COALESCE(p.p_promo_name, 'No Promo')           AS promo_name,
  SUM(ws.ws_ext_sales_price)                     AS total_sales_amount,
  SUM(ws.ws_net_profit)                          AS total_sales_profit,
  SUM(sr.sr_net_loss)                           AS total_store_return_loss,
  SUM(cr.cr_net_loss)                           AS total_catalog_return_loss,
  SUM(wr.wr_net_loss)                           AS total_web_return_loss,
  COUNT(DISTINCT ws.ws_order_number)             AS distinct_sales_orders,
  CASE
    WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
    ELSE (SUM(ws.ws_net_profit) - (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)))
         / SUM(ws.ws_ext_sales_price)
  END                                            AS adjusted_profit_margin,
  (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_net_loss > 1000) AS high_loss_return_count,
  (SELECT SUM(amt) FROM (
       SELECT ws2.ws_ext_sales_price AS amt
       FROM web_sales ws2
       WHERE ws2.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
       UNION ALL
       SELECT cr2.cr_return_amount
       FROM catalog_returns cr2
       WHERE cr2.cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
   ))                                            AS total_union_amount
FROM d
-- Store (closed‑date link)
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
-- Store returns and their related dimensions
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t_sr ON t_sr.t_time_sk = sr.sr_return_time_sk
JOIN customer_demographics cd_sr ON cd_sr.cd_demo_sk = sr.sr_cdemo_sk
JOIN customer_address ca_sr ON ca_sr.ca_address_sk = sr.sr_addr_sk
-- Catalog returns and related dimensions
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t_cr ON t_cr.t_time_sk = cr.cr_returned_time_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN warehouse w_cr ON w_cr.w_warehouse_sk = cr.cr_warehouse_sk
-- Web sales and all of its dimensions (bill and ship sides, page, promo, warehouse)
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t_ws ON t_ws.t_time_sk = ws.ws_sold_time_sk
JOIN d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill ON cd_bill.cd_demo_sk = ws.ws_bill_cdemo_sk
JOIN customer_address ca_bill ON ca_bill.ca_address_sk = ws.ws_bill_addr_sk
JOIN customer_demographics cd_ship ON cd_ship.cd_demo_sk = ws.ws_ship_cdemo_sk
JOIN customer_address ca_ship ON ca_ship.ca_address_sk = ws.ws_ship_addr_sk
JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN warehouse w_ws ON w_ws.w_warehouse_sk = ws.ws_warehouse_sk
JOIN promotion p ON p.p_promo_sk = ws.ws_promo_sk
-- Web returns and their related dimensions
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t_wr ON t_wr.t_time_sk = wr.wr_returned_time_sk
JOIN web_page wp_ret ON wp_ret.wp_web_page_sk = wr.wr_web_page_sk
-- Link each web return to the original web sale (order & item keys)
JOIN web_sales ws2 ON ws2.ws_order_number = wr.wr_order_number
                 AND ws2.ws_item_sk = wr.wr_item_sk
WHERE d.d_year = 2001
GROUP BY
  COALESCE(s.s_store_name, 'All Stores'),
  COALESCE(p.p_promo_name, 'No Promo')
ORDER BY total_sales_amount DESC
LIMIT 100
