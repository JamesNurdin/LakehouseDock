SELECT
    d.d_year AS year,
    i.i_category AS category,
    s.s_state AS state,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    MAX(cs.cs_sales_price) AS max_sales_price
FROM
    date_dim d
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN item i
    ON i.i_item_sk = cs.cs_item_sk
JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN reason r
    ON r.r_reason_sk = cr.cr_reason_sk
JOIN web_site wsit
    ON wsit.web_site_sk = ws.ws_web_site_sk
JOIN time_dim t
    ON t.t_time_sk = cs.cs_sold_time_sk
WHERE
    d.d_year = 2001
    AND i.i_units = 'Box'
    AND c.c_birth_month = 7
    AND s.s_state = 'CA'
GROUP BY
    d.d_year,
    i.i_category,
    s.s_state
LIMIT 100
