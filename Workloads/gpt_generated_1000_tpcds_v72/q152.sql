WITH wh_union AS (
    SELECT w_warehouse_sk, w_city, w_county
    FROM warehouse
    UNION
    SELECT w_warehouse_sk, w_city, w_county
    FROM warehouse
    WHERE w_warehouse_sq_ft > 500000
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    w.w_warehouse_name,
    w.w_county,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory,
    MIN(ib.ib_upper_bound) AS min_income_band_upper,
    MAX(ib.ib_upper_bound) AS max_income_band_upper
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN household_demographics hd_cs_bill
    ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
JOIN household_demographics hd_cs_ship
    ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib
    ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship
    ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE EXISTS (
        SELECT 1
        FROM wh_union wu
        WHERE wu.w_warehouse_sk = w.w_warehouse_sk
      )
  AND ib.ib_upper_bound > 50000
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    w.w_warehouse_name,
    w.w_county
ORDER BY total_store_sales DESC
LIMIT 100
