SELECT
    cc.cc_company_name,
    cc.cc_market_manager,
    dd.d_year AS sales_year,
    dd.d_month_seq AS sales_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_city,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_transactions
FROM call_center AS cc
JOIN date_dim AS dd ON cc.cc_closed_date_sk = dd.d_date_sk
JOIN date_dim AS dd_open ON cc.cc_open_date_sk = dd_open.d_date_sk
JOIN store_sales AS ss ON ss.ss_sold_date_sk = dd.d_date_sk
JOIN store AS s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim AS dd_store ON s.s_closed_date_sk = dd_store.d_date_sk
JOIN promotion AS p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim AS dd_promo_start ON p.p_start_date_sk = dd_promo_start.d_date_sk
JOIN date_dim AS dd_promo_end ON p.p_end_date_sk = dd_promo_end.d_date_sk
WHERE dd.d_year = 2022
GROUP BY
    cc.cc_company_name,
    cc.cc_market_manager,
    dd.d_year,
    dd.d_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_city
ORDER BY total_sales DESC
LIMIT 100
