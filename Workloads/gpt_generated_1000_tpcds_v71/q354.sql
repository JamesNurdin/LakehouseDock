WITH ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
)
SELECT
    d_sold.d_year AS sales_year,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_type,
    SUM(ws_base.ws_net_paid) AS total_net_paid,
    SUM(ws_base.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_return_amount,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return_amount,
    (
        SELECT MAX(d_prev.d_year)
        FROM date_dim d_prev
        WHERE d_prev.d_year < d_sold.d_year
    ) AS previous_year
FROM ws_base
-- Core sales dimensions
JOIN date_dim d_sold ON ws_base.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws_base.ws_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
JOIN ship_mode sm ON ws_base.ws_ship_mode_sk = sm.sm_ship_mode_sk
-- Bill‑side customer hierarchy
JOIN customer cust_bill ON ws_base.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cust_bill.c_current_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cust_bill.c_current_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cust_bill.c_current_addr_sk = ca_bill.ca_address_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
-- Ship‑side customer hierarchy (different alias, same join rules)
JOIN customer cust_ship ON ws_base.ws_ship_customer_sk = cust_ship.c_customer_sk
-- Catalog returns (joined through call center, then further dimensions)
LEFT JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r_catalog ON cr.cr_reason_sk = r_catalog.r_reason_sk
LEFT JOIN date_dim d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
LEFT JOIN time_dim t_cr_returned ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
-- Store returns (joined via the same sold‑date dimension, different role)
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
LEFT JOIN customer cust_return ON sr.sr_customer_sk = cust_return.c_customer_sk
LEFT JOIN customer_demographics cd_return ON cust_return.c_current_cdemo_sk = cd_return.cd_demo_sk
LEFT JOIN household_demographics hd_return ON cust_return.c_current_hdemo_sk = hd_return.hd_demo_sk
LEFT JOIN customer_address ca_return ON cust_return.c_current_addr_sk = ca_return.ca_address_sk
-- Inventory (joined only to demonstrate use of the table)
LEFT JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = ws_base.ws_order_number
      AND cr2.cr_return_quantity > 0
)
GROUP BY ROLLUP (d_sold.d_year, cc.cc_name, sm.sm_type)
ORDER BY total_net_paid DESC
LIMIT 100
