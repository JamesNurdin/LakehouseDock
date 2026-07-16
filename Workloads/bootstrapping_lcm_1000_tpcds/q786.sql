SELECT
    cc.cc_division,
    cc.cc_city,
    s.s_state,
    d_sales.d_year,
    p.p_channel_tv,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MIN(d_sales.d_date) AS first_sale_date,
    MAX(d_sales.d_date) AS last_sale_date,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MIN(d_store_closed.d_date) AS store_closed_date,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    cc.cc_division,
    cc.cc_city,
    s.s_state,
    d_sales.d_year,
    p.p_channel_tv
ORDER BY total_sales DESC
LIMIT 100
