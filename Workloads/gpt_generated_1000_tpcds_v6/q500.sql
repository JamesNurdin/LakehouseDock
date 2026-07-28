WITH max_income AS (
    SELECT MAX(ib_upper_bound) AS max_ub
    FROM income_band
)
SELECT
    d.d_year,
    d.d_month_seq,
    c.c_customer_id,
    ca.ca_state,
    sm.sm_carrier,
    ws.ws_net_paid,
    ss.ss_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    MIN(ss.ss_ext_discount_amt) AS min_store_discount,
    MAX(ib.ib_upper_bound) AS max_income_upper,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS overall_max_income
FROM
    date_dim d
LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
    AND ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_order_number = ws.ws_order_number
WHERE
    d.d_year = 2000
    AND d.d_month_seq BETWEEN 1 AND 12
    AND sm.sm_carrier = 'TBS'
    AND site.web_company_name = 'pri'
    AND ib.ib_upper_bound >= 50000
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    d.d_year,
    d.d_month_seq,
    c.c_customer_id,
    ca.ca_state,
    sm.sm_carrier,
    ws.ws_net_paid,
    ss.ss_net_paid,
    ib.ib_upper_bound
HAVING
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY
    total_web_sales DESC
LIMIT 100
