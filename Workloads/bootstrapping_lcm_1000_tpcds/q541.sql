SELECT
    d_sales.d_year,
    s.s_state,
    p.p_channel_tv,
    CASE 
        WHEN p.p_discount_active = 'Y' THEN 'Active'
        ELSE 'Inactive'
    END AS promo_status,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN 1 ELSE 0 END) AS landing_pages,
    SUM(CASE WHEN wp.wp_type = 'Product' THEN 1 ELSE 0 END) AS product_pages,
    MIN(d_close.d_date) AS store_close_date,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MIN(d_promo_end.d_date) AS promo_end_date
FROM date_dim d_sales
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_close
    ON s.s_closed_date_sk = d_close.d_date_sk
LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sales.d_year BETWEEN 2020 AND 2022
  AND s.s_state IS NOT NULL
GROUP BY
    d_sales.d_year,
    s.s_state,
    p.p_channel_tv,
    CASE 
        WHEN p.p_discount_active = 'Y' THEN 'Active'
        ELSE 'Inactive'
    END
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
