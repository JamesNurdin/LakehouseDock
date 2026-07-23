WITH
inventory_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
        MAX(cs.cs_call_center_sk) AS call_center_sk,
        MAX(cs.cs_catalog_page_sk) AS catalog_page_sk,
        MAX(cs.cs_ship_mode_sk) AS ship_mode_sk,
        MAX(cs.cs_promo_sk) AS promo_sk,
        MAX(cs.cs_bill_customer_sk) AS bill_customer_sk,
        MAX(cs.cs_ship_customer_sk) AS ship_customer_sk,
        MAX(cs.cs_bill_cdemo_sk) AS bill_cdemo_sk,
        MAX(cs.cs_ship_cdemo_sk) AS ship_cdemo_sk,
        MAX(cs.cs_bill_hdemo_sk) AS bill_hdemo_sk,
        MAX(cs.cs_ship_hdemo_sk) AS ship_hdemo_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk, cs.cs_order_number
)

SELECT
    c_bill.c_customer_id        AS billing_customer_id,
    c_ship.c_customer_id        AS shipping_customer_id,
    cd_bill.cd_gender           AS billing_gender,
    cd_ship.cd_gender           AS shipping_gender,
    hd_bill.hd_income_band_sk   AS billing_income_band,
    hd_ship.hd_income_band_sk   AS shipping_income_band,
    ib_bill.ib_upper_bound      AS billing_income_upper,
    ib_ship.ib_upper_bound      AS shipping_income_upper,
    cc.cc_name                  AS call_center_name,
    cp.cp_department            AS catalog_department,
    p_cat.p_promo_id            AS catalog_promo_id,
    p_web.p_promo_id            AS web_promo_id,
    sm_cat.sm_type              AS catalog_ship_mode_type,
    sm_web.sm_type              AS web_ship_mode_type,
    wh.w_warehouse_name         AS warehouse_name,
    inv_agg.total_qty_on_hand   AS warehouse_total_on_hand,
    SUM(cs_agg.total_quantity_sold) AS total_catalog_quantity_sold,
    SUM(cs_agg.total_net_paid)      AS total_catalog_net_paid,
    SUM(ws.ws_quantity)             AS total_web_quantity,
    SUM(ws.ws_net_paid)             AS total_web_net_paid,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_returns,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_returns,
    COUNT(DISTINCT sr.sr_return_quantity) AS distinct_store_return_quantity
FROM cs_agg
JOIN call_center cc
    ON cs_agg.call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_agg.catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p_cat
    ON cs_agg.promo_sk = p_cat.p_promo_sk
JOIN ship_mode sm_cat
    ON cs_agg.ship_mode_sk = sm_cat.sm_ship_mode_sk
JOIN warehouse wh
    ON cs_agg.cs_warehouse_sk = wh.w_warehouse_sk
JOIN inventory_agg inv_agg
    ON wh.w_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN customer c_bill
    ON cs_agg.bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs_agg.ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs_agg.bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs_agg.ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs_agg.bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs_agg.ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs_agg.cs_order_number
   AND cr.cr_item_sk = cs_agg.cs_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN web_sales ws
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
LEFT JOIN promotion p_web
    ON ws.ws_promo_sk = p_web.p_promo_sk
LEFT JOIN ship_mode sm_web
    ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN customer c_web
    ON wp.wp_customer_sk = c_web.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
WHERE EXISTS (
    SELECT 1
    FROM income_band ib_check
    WHERE ib_check.ib_income_band_sk = hd_bill.hd_income_band_sk
      AND ib_check.ib_upper_bound > 50000
)
  AND cs_agg.cs_order_number IN (
    SELECT DISTINCT cr2.cr_order_number
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 0
)
GROUP BY
    c_bill.c_customer_id,
    c_ship.c_customer_id,
    cd_bill.cd_gender,
    cd_ship.cd_gender,
    hd_bill.hd_income_band_sk,
    hd_ship.hd_income_band_sk,
    ib_bill.ib_upper_bound,
    ib_ship.ib_upper_bound,
    cc.cc_name,
    cp.cp_department,
    p_cat.p_promo_id,
    p_web.p_promo_id,
    sm_cat.sm_type,
    sm_web.sm_type,
    wh.w_warehouse_name,
    inv_agg.total_qty_on_hand
ORDER BY total_catalog_net_paid DESC
LIMIT 100
