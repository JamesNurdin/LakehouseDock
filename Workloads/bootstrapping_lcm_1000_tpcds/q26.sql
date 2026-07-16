SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    CAST(d_store.d_year AS VARCHAR) || '-' || LPAD(CAST(d_store.d_moy AS VARCHAR), 2, '0') AS store_closed_ym,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT p.p_promo_id) AS num_promos,
    AVG(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost END) AS avg_active_promo_cost,
    SUM(CASE WHEN d_sales.d_year = d_store.d_year THEN 1 ELSE 0 END) AS same_year_sales_count,
    COUNT(DISTINCT CASE WHEN d_sales.d_year = d_store.d_year THEN c.c_customer_id END) AS distinct_customers_same_year
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_store.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_store.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_store.d_year,
    d_store.d_moy
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY total_promo_cost DESC
LIMIT 100
