SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    CASE
        WHEN d_sold.d_month_seq <= 6 THEN 'First Half'
        ELSE 'Second Half'
    END AS half_year,
    s.s_division_id,
    ws.web_mkt_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
    AVG(wp.wp_image_count) AS avg_image_count,
    AVG(ws.web_tax_percentage) AS avg_web_tax,
    SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_ext_sales_price ELSE 0 END) AS profit_sales,
    COUNT(*) AS rows_count
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_division_id,
    ws.web_mkt_id
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
