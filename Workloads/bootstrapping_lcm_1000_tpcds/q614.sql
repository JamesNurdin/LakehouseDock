SELECT
    s.s_store_name,
    s.s_city,
    cd.cd_gender,
    cd.cd_education_status,
    d_sale.d_year,
    d_sale.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS profit_margin,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    MAX(d_web_access.d_date) AS last_web_access_date
FROM store_sales ss
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN date_dim d_store_close
    ON s.s_closed_date_sk = d_store_close.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store_close.d_date_sk
JOIN date_dim d_web_access
    ON wp.wp_access_date_sk = d_web_access.d_date_sk
WHERE d_sale.d_year = 2022
GROUP BY
    s.s_store_name,
    s.s_city,
    cd.cd_gender,
    cd.cd_education_status,
    d_sale.d_year,
    d_sale.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
