WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid
    FROM tpcds.item i
    LEFT JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category, i.i_brand, i.i_current_price
)
SELECT
    i_sales.i_item_id,
    i_sales.i_category,
    i_sales.i_brand,
    i_sales.i_current_price,
    i_sales.catalog_net_paid,
    i_sales.store_net_paid,
    i_sales.web_net_paid,
    CASE WHEN i_sales.catalog_net_paid > 10000 THEN 'High' ELSE 'Low' END AS catalog_sales_category,
    (i_sales.i_current_price > (SELECT MAX(i_current_price) FROM tpcds.item) / 2) AS price_above_half_max,
    cc.cc_name,
    cp.cp_type,
    sm.sm_carrier,
    inv.inv_quantity_on_hand,
    sr.sr_net_loss,
    cr.cr_net_loss,
    ws_page.wp_type,
    ws_site.web_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city
FROM item_sales i_sales
-- first role for catalog_sales (billing side)
LEFT JOIN tpcds.catalog_sales cs_join ON cs_join.cs_item_sk = i_sales.i_item_sk
-- second role for catalog_sales (shipping side)
LEFT JOIN tpcds.catalog_sales cs_ship ON cs_ship.cs_item_sk = i_sales.i_item_sk
LEFT JOIN tpcds.call_center cc ON cs_join.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.catalog_page cp ON cs_join.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN tpcds.ship_mode sm ON cs_join.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN tpcds.inventory inv ON inv.inv_item_sk = i_sales.i_item_sk
LEFT JOIN tpcds.store_returns sr ON sr.sr_item_sk = i_sales.i_item_sk
LEFT JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i_sales.i_item_sk
LEFT JOIN tpcds.web_sales ws ON ws.ws_item_sk = i_sales.i_item_sk
LEFT JOIN tpcds.web_page ws_page ON ws.ws_web_page_sk = ws_page.wp_web_page_sk
LEFT JOIN tpcds.web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN tpcds.customer_demographics cd ON cs_join.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN tpcds.household_demographics hd ON cs_join.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.customer_address ca_bill ON cs_join.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN tpcds.customer_address ca_ship ON cs_ship.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE i_sales.i_current_price IS NOT NULL
ORDER BY i_sales.catalog_net_paid DESC
LIMIT 100
