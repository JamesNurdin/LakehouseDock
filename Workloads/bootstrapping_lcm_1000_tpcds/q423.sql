SELECT
    s.s_store_id,
    s.s_state,
    p.p_promo_name,
    CASE
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        ELSE 'Other'
    END AS promo_channel_type,
    d_sales.d_year AS sales_year,
    d_store_closed.d_year AS store_closed_year,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 0
         THEN COALESCE(SUM(cr.cr_return_amount), 0) / SUM(ss.ss_ext_sales_price)
    END AS return_to_sales_ratio,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 0
         THEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
    END AS profit_margin
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sales.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_state,
    p.p_promo_name,
    CASE
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        ELSE 'Other'
    END,
    d_sales.d_year,
    d_store_closed.d_year,
    d_promo_start.d_date,
    d_promo_end.d_date
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
