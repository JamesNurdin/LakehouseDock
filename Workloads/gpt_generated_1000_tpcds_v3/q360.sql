SELECT
    site.web_company_name,
    site.web_county,
    sm.sm_type,
    hd.hd_buy_potential,
    w.w_city,
    ib.ib_lower_bound,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_web_discount,
    SUM(ss.ss_ext_discount_amt) AS total_store_discount,
    AVG(ws.ws_quantity) AS avg_web_quantity,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    MIN(ws.ws_ship_date_sk) AS earliest_ship_date_sk,
    MAX(ws.ws_ship_date_sk) AS latest_ship_date_sk
FROM
    web_sales ws
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    ws.ws_quantity > 5
    AND ws.ws_net_paid > 500
    AND ws.ws_ext_discount_amt > 100
    AND ss.ss_wholesale_cost > 30
    AND ss.ss_coupon_amt > 1000
    AND inv.inv_quantity_on_hand < 500
    AND hd.hd_vehicle_count >= 2
    AND ib.ib_lower_bound >= 50000
    AND site.web_company_name LIKE 'a%'
    AND site.web_county = 'Raleigh County'
GROUP BY
    site.web_company_name,
    site.web_county,
    sm.sm_type,
    hd.hd_buy_potential,
    w.w_city,
    ib.ib_lower_bound,
    p.p_promo_name
LIMIT 100
