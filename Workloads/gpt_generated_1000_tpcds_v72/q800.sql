WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_net_profit AS catalog_net_profit,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_item_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk
    FROM catalog_sales cs
    WHERE EXISTS (
        SELECT 1 FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_discount_active = 'Y'
    )
)
SELECT
    ca_bill.ca_country AS country,
    bs.cs_sold_date_sk AS sold_date,
    p.p_promo_name,
    SUM(bs.catalog_net_profit) +
    SUM(ws.ws_net_profit) -
    SUM(COALESCE(cr.cr_net_loss, 0)) -
    SUM(COALESCE(wr.wr_net_loss, 0)) -
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_profit,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_customers,
    ROW_NUMBER() OVER (
        PARTITION BY ca_bill.ca_country
        ORDER BY SUM(bs.catalog_net_profit) +
                 SUM(ws.ws_net_profit) -
                 SUM(COALESCE(cr.cr_net_loss, 0)) -
                 SUM(COALESCE(wr.wr_net_loss, 0)) -
                 SUM(COALESCE(sr.sr_net_loss, 0)) DESC
    ) AS rn
FROM base_sales bs
JOIN time_dim t_sold ON bs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill ON bs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON bs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill ON bs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON bs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON bs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship ON bs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON bs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship ON bs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN call_center cc ON bs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON bs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON bs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON bs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON bs.cs_promo_sk = p.p_promo_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
-- Catalog Returns
LEFT JOIN catalog_returns cr ON cr.cr_order_number = bs.cs_order_number
    AND cr.cr_item_sk = bs.cs_item_sk
LEFT JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
LEFT JOIN reason r_ret ON cr.cr_reason_sk = r_ret.r_reason_sk
LEFT JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
LEFT JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
-- Web Sales
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web_s ON ws.ws_web_site_sk = web_s.web_site_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
-- Web Returns
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
-- Store Returns
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c_bill.c_customer_sk
LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
WHERE EXISTS (
    SELECT 1 FROM web_returns wr2
    WHERE wr2.wr_returning_customer_sk = c_bill.c_customer_sk
)
GROUP BY ROLLUP (ca_bill.ca_country, bs.cs_sold_date_sk, p.p_promo_name)
ORDER BY total_net_profit DESC
LIMIT 100
