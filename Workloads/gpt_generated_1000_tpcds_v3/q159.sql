WITH cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity >= 2
      AND cs.cs_sales_price > 100.00
)
SELECT
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    sm.sm_type,
    web.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_profit) AS total_cs_net_profit,
    SUM(ws.ws_net_profit) AS total_ws_net_profit,
    SUM(sr.sr_net_loss) AS total_sr_net_loss,
    AVG(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_sales_price END) AS avg_high_quantity_price,
    SUM(CASE WHEN sr.sr_fee > 20.00 THEN sr.sr_refunded_cash ELSE 0 END) AS total_refunded_cash_high_fee
FROM cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics sr_cd ON sr.sr_cdemo_sk = sr_cd.cd_demo_sk
JOIN household_demographics sr_hd ON sr.sr_hdemo_sk = sr_hd.hd_demo_sk
JOIN customer_address sr_ca ON sr.sr_addr_sk = sr_ca.ca_address_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN customer_demographics ws_cd_bill ON ws.ws_bill_cdemo_sk = ws_cd_bill.cd_demo_sk
JOIN household_demographics ws_hd_bill ON ws.ws_bill_hdemo_sk = ws_hd_bill.hd_demo_sk
JOIN customer_address ws_ca_bill ON ws.ws_bill_addr_sk = ws_ca_bill.ca_address_sk
JOIN customer_demographics ws_cd_ship ON ws.ws_ship_cdemo_sk = ws_cd_ship.cd_demo_sk
JOIN household_demographics ws_hd_ship ON ws.ws_ship_hdemo_sk = ws_hd_ship.hd_demo_sk
JOIN customer_address ws_ca_ship ON ws.ws_ship_addr_sk = ws_ca_ship.ca_address_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE cc.cc_state = 'CA'
  AND cp.cp_type = 'quarterly'
  AND hd_bill.hd_vehicle_count >= 2
  AND sr.sr_fee > 20.00
GROUP BY cc.cc_name, cp.cp_department, i.i_category, sm.sm_type, web.web_name
ORDER BY total_cs_net_profit DESC
LIMIT 100
