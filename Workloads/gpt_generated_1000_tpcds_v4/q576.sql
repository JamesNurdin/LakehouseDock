WITH base_date AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    d.d_year,
    cc.cc_state,
    ib.ib_upper_bound,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM call_center cc
JOIN base_date d ON cc.cc_open_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    cc.cc_state = 'CA'
    AND ib.ib_lower_bound >= 50000
    AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
GROUP BY
    d.d_year,
    cc.cc_state,
    ib.ib_upper_bound,
    sm.sm_type
HAVING
    SUM(ss.ss_ext_sales_price) > 1000000
ORDER BY
    total_store_sales DESC
LIMIT 100
