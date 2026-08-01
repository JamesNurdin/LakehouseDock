/* goal: Summarize combined catalog and web sales performance by call center, customer income band, promotion and shipping mode, showing total net paid and order counts */
WITH cs_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_net_paid
    FROM tpcds.catalog_sales cs
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws
        WHERE ws.ws_item_sk = cs.cs_item_sk
          AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    )
)
SELECT
    cc.cc_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    sm.sm_type,
    i.i_category,
    COUNT(DISTINCT cs_base.cs_order_number) AS order_cnt,
    SUM(cs_base.cs_net_paid) AS catalog_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(cs_base.cs_net_paid + ws.ws_net_paid) AS total_net_paid
FROM cs_base
JOIN tpcds.call_center cc
    ON cs_base.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON cs_base.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.item i
    ON cs_base.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p
    ON cs_base.cs_promo_sk = p.p_promo_sk
JOIN tpcds.household_demographics hd_bill
    ON cs_base.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
    ON cs_base.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs_base.cs_order_number
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = cs_base.cs_item_sk
JOIN tpcds.web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN tpcds.item i_ws
    ON ws.ws_item_sk = i_ws.i_item_sk
JOIN tpcds.ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN tpcds.promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN tpcds.household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
WHERE cc.cc_tax_percentage > 0.01
GROUP BY
    cc.cc_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    sm.sm_type,
    i.i_category
ORDER BY total_net_paid DESC
LIMIT 100
