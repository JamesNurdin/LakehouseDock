WITH 
    -- Alias the date dimension for each role
    d_sales AS (SELECT * FROM date_dim),
    d_return AS (SELECT * FROM date_dim),
    d_ws_ship AS (SELECT * FROM date_dim),
    d_cp_start AS (SELECT * FROM date_dim),
    d_cp_end AS (SELECT * FROM date_dim),
    t_sales AS (SELECT * FROM time_dim),
    t_return AS (SELECT * FROM time_dim),
    t_ws AS (SELECT * FROM time_dim)
SELECT
    d_sales.d_year,
    c.c_customer_id,
    hd_cust.hd_income_band_sk,
    r.r_reason_desc,
    web.web_site_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty,
    (
        SELECT avg(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sales.d_year
    ) AS avg_store_profit_year
FROM store_sales ss
JOIN d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd_cust ON ss.ss_hdemo_sk = hd_cust.hd_demo_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_page cp_start ON cp_start.cp_start_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_page cp_end ON cp_end.cp_end_date_sk = d_sales.d_date_sk
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN t_return ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd_return ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
GROUP BY
    d_sales.d_year,
    c.c_customer_id,
    hd_cust.hd_income_band_sk,
    r.r_reason_desc,
    web.web_site_id
ORDER BY total_store_profit DESC
LIMIT 100
