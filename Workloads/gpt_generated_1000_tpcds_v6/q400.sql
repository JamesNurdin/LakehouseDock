WITH
  store_data AS (
    SELECT
      s.s_store_id                     AS channel_id,
      'Store'                          AS channel_type,
      i.i_item_id                      AS i_item_id,
      SUM(ss.ss_ext_sales_price)      AS sales_amount,
      SUM(ss.ss_net_profit)           AS profit_amount,
      CASE
        WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
        WHEN SUM(ss.ss_net_profit) > 1000  THEN 'Medium'
        ELSE 'Low'
      END                             AS profit_category
    FROM store_sales ss
      JOIN item i               ON ss.ss_item_sk = i.i_item_sk
      JOIN store s              ON ss.ss_store_sk = s.s_store_sk
      JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
      JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
      LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
      LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
      JOIN inventory inv        ON i.i_item_sk = inv.inv_item_sk
      JOIN warehouse w          ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE s.s_country = 'United States'
      AND ss.ss_net_paid > 1000
      AND i.i_current_price BETWEEN 5 AND 50
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc = 'Damaged'
    GROUP BY s.s_store_id, i.i_item_id
  ),
  web_data AS (
    SELECT
      wsit.web_site_id                AS channel_id,
      'Web'                           AS channel_type,
      i.i_item_id                     AS i_item_id,
      SUM(ws.ws_ext_sales_price)      AS sales_amount,
      SUM(ws.ws_net_profit)           AS profit_amount,
      CASE
        WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High'
        WHEN SUM(ws.ws_net_profit) > 1000  THEN 'Medium'
        ELSE 'Low'
      END                             AS profit_category
    FROM web_sales ws
      JOIN item i               ON ws.ws_item_sk = i.i_item_sk
      JOIN web_site wsit        ON ws.ws_web_site_sk = wsit.web_site_sk
      JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
      JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
      JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
      LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND wr.wr_item_sk = i.i_item_sk
      LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
      JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE wsit.web_state = 'CA'
      AND ws.ws_net_paid > 1500
      AND i.i_current_price BETWEEN 10 AND 60
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc = 'Customer Return'
    GROUP BY wsit.web_site_id, i.i_item_id
  ),
  combined AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
  )
SELECT
  channel_type,
  channel_id,
  i_item_id,
  sales_amount,
  profit_amount,
  profit_category,
  ROW_NUMBER() OVER (PARTITION BY channel_type ORDER BY sales_amount DESC) AS sales_rank
FROM combined
ORDER BY channel_type, sales_rank
