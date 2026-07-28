WITH
  ss_join AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_cdemo_sk,
      ss.ss_promo_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d_s.d_year,
      i.i_category,
      i.i_product_name,
      c.cd_purchase_estimate,
      p.p_promo_name
    FROM store_sales ss
    JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics c ON ss.ss_cdemo_sk = c.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d_s.d_year = 2001
      AND i.i_current_price > 50
      AND c.cd_purchase_estimate >= 5000
      AND p.p_promo_name LIKE '%Clearance%'
  ),
  sr_join AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      d_r.d_year AS return_year,
      sr.sr_return_amt,
      sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d_r ON sr.sr_returned_date_sk = d_r.d_date_sk
    WHERE d_r.d_year = 2001
  ),
  ws_join AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk,
      ws.ws_promo_sk,
      ws.ws_net_profit,
      d_ws.d_year,
      i2.i_category,
      wp.wp_type,
      wp.wp_access_date_sk,
      ws.ws_quantity,
      wsit.web_tax_percentage
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    WHERE d_ws.d_year = 2001
      AND wp.wp_type = 'order'
      AND wsit.web_tax_percentage > 0.05
      AND ws.ws_quantity > 1
  ),
  cp_join AS (
    SELECT
      cp.cp_catalog_page_id,
      cp.cp_department,
      d_cp_start.d_year AS start_year,
      d_cp_end.d_year AS end_year
    FROM catalog_page cp
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end   ON cp.cp_end_date_sk   = d_cp_end.d_date_sk
    WHERE d_cp_start.d_year = 2001
  )
SELECT
  s.i_category,
  s.i_product_name,
  s.cd_purchase_estimate,
  s.p_promo_name,
  w.wp_type,
  w.wp_access_date_sk,
  w.ws_net_profit,
  s.ss_net_profit,
  r.sr_net_loss,
  ROW_NUMBER() OVER (PARTITION BY s.i_category ORDER BY s.ss_net_profit DESC) AS prod_profit_rank,
  CASE
    WHEN s.ss_net_profit > 1000 THEN 'High'
    WHEN s.ss_net_profit BETWEEN 500 AND 1000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_band,
  (
    SELECT COUNT(*)
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = s.ss_item_sk
      AND ss2.ss_sold_date_sk = s.ss_sold_date_sk
  ) AS daily_sales_count
FROM ss_join s
LEFT JOIN sr_join r ON s.ss_ticket_number = r.sr_ticket_number
LEFT JOIN ws_join w ON s.ss_item_sk = w.ws_item_sk
LEFT JOIN cp_join cp ON cp.start_year = s.d_year
LIMIT 100
