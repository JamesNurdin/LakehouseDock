WITH base AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    cp.cp_type,
    cc.cc_state,
    sm.sm_type,
    p.p_discount_active,
    s.s_store_name,
    cs.cs_net_profit,
    cs.cs_quantity,
    ws.ws_net_profit,
    ws.ws_quantity,
    sr.sr_net_loss,
    sr.sr_return_quantity,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    wr.wr_net_loss,
    wr.wr_return_quantity
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  LEFT JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_returned_date_sk = d.d_date_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Jewelry'
    AND cp.cp_type = 'monthly'
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'TX'
)
SELECT
  d_year,
  i_category,
  cp_type,
  s_store_name,
  SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(sr_net_loss) - SUM(cr_net_loss) - SUM(wr_net_loss) AS total_profit,
  SUM(cs_quantity) + SUM(ws_quantity) + SUM(sr_return_quantity) + SUM(cr_return_quantity) + SUM(wr_return_quantity) AS total_units
FROM base
GROUP BY d_year, i_category, cp_type, s_store_name
HAVING SUM(cs_net_profit) > 100000
ORDER BY total_profit DESC
LIMIT 100
