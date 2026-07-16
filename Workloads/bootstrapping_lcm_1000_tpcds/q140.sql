SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    d_sales.d_date,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(cp.cp_description) AS catalog_desc
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN catalog_page cp
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE
    d_sales.d_date BETWEEN d_cp_start.d_date AND d_cp_end.d_date
    AND d_sales.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
    AND (d_store_closed.d_date IS NULL OR d_sales.d_date <= d_store_closed.d_date)
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    d_sales.d_date,
    d_sales.d_year,
    d_sales.d_month_seq
HAVING
    SUM(ss.ss_ext_sales_price) > 1000
ORDER BY
    total_sales DESC
LIMIT 100
