WITH joined AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_quantity,
    ss.ss_ticket_number,
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    i.i_current_price,
    c.c_customer_sk,
    cd.cd_gender,
    ca.ca_state,
    s.s_store_sk,
    s.s_store_id,
    s.s_market_id,
    p.p_promo_sk,
    p.p_discount_active,
    sm.sm_carrier,
    cp.cp_department,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    ws.ws_quantity,
    ws.ws_net_profit,
    inv.inv_quantity_on_hand
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    AND cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_addr_sk = ca.ca_address_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_addr_sk = ca.ca_address_sk
    AND ws.ws_ship_customer_sk = c.c_customer_sk
    AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_ship_addr_sk = ca.ca_address_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_promo_sk = p.p_promo_sk
  WHERE s.s_market_id IN (1, 2, 3)
    AND ca.ca_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND p.p_discount_active = 'Y'
    AND sm.sm_carrier = 'FEDEX'
    AND inv.inv_quantity_on_hand > 100
    AND ss.ss_ext_sales_price > 500
),
aggregated AS (
  SELECT
    s_store_id,
    i_category,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(ws_net_profit) AS total_web_profit,
    COUNT(*) AS transaction_count,
    AVG(ss_ext_sales_price) AS avg_sale_price
  FROM joined
  GROUP BY s_store_id, i_category
)
SELECT
  a.s_store_id,
  a.i_category,
  a.total_store_profit,
  a.total_web_profit,
  a.transaction_count,
  a.avg_sale_price,
  (SELECT AVG(total_store_profit) FROM aggregated) AS overall_avg_store_profit
FROM aggregated a
WHERE a.total_store_profit > (SELECT AVG(total_store_profit) FROM aggregated)
ORDER BY a.total_store_profit DESC
LIMIT 100
