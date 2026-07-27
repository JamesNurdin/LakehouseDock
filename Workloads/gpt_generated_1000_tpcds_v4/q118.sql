WITH combined AS (
  SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    cp.cp_catalog_page_id,
    p.p_promo_name,
    sm.sm_type AS ship_mode,
    ca.ca_city,
    hd.hd_income_band_sk,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS store_sale_status,
    ws.ws_order_number,
    ws.ws_quantity AS ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS web_sale_status
  FROM date_dim d
  LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
  LEFT JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
  LEFT JOIN item i
    ON p.p_item_sk = i.i_item_sk
  LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_item_sk = i.i_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND hd.hd_vehicle_count >= 2
    AND i.i_current_price BETWEEN 10 AND 1000
    AND ca.ca_state = 'CA'
    AND p.p_discount_active = 'Y'
)
SELECT
  d_date,
  i_item_id,
  i_product_name,
  cp_catalog_page_id,
  p_promo_name,
  ship_mode,
  ca_city,
  hd_income_band_sk,
  ss_ticket_number,
  ss_ext_sales_price,
  ss_net_profit,
  store_sale_status,
  ws_ext_sales_price,
  ws_net_profit,
  web_sale_status,
  ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY ss_net_profit DESC) AS store_profit_rank,
  RANK()        OVER (PARTITION BY i_item_id ORDER BY ws_net_profit DESC) AS web_profit_rank
FROM combined
ORDER BY d_date DESC, ss_net_profit DESC
LIMIT 100
