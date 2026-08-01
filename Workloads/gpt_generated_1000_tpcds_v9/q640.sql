WITH joined_data AS (
    SELECT
        t.t_hour,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_ship_cost,
        cr.cr_store_credit,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        ws_site.web_name,
        ws_site.web_country
    FROM time_dim t
    JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND ss.ss_ext_sales_price > 1000.00
        AND sr.sr_return_amt > 100.00
        AND cr.cr_return_amount > 50.00
        AND ws.ws_wholesale_cost BETWEEN 30.00 AND 80.00
        AND w.w_warehouse_sq_ft > 100000
        AND ws_site.web_country = 'United States'
)
SELECT
    jd.t_hour,
    jd.w_warehouse_name,
    jd.web_name,
    COUNT(DISTINCT jd.ss_ticket_number) AS num_sales,
    SUM(jd.ss_ext_sales_price) AS total_sales,
    SUM(jd.sr_return_amt) AS total_returns,
    SUM(jd.cr_return_amount) AS total_catalog_returns,
    SUM(jd.ws_ext_sales_price) AS total_web_sales,
    AVG(CASE WHEN jd.ss_quantity > 5 THEN jd.ss_ext_sales_price ELSE NULL END) AS avg_large_sale_amount,
    MIN(jd.ss_sales_price) AS min_sales_price,
    MAX(jd.ss_sales_price) AS max_sales_price
FROM joined_data jd
WHERE jd.ss_ticket_number NOT IN (
    SELECT ws_order_number FROM web_sales WHERE ws_quantity > 10
)
GROUP BY
    jd.t_hour,
    jd.w_warehouse_name,
    jd.web_name
HAVING
    SUM(jd.ss_ext_sales_price) > 50000
    AND COUNT(DISTINCT jd.ss_ticket_number) >= 10
    AND SUM(jd.cr_return_amount) < 10000
ORDER BY
    total_sales DESC,
    jd.t_hour ASC
LIMIT 100
