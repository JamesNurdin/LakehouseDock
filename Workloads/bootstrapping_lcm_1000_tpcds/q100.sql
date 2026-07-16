SELECT
    s.s_city,
    s.s_state,
    cd.cd_gender,
    cd.cd_marital_status,
    DATE_TRUNC('month', d_shipto.d_date) AS shipto_month,
    COUNT(DISTINCT c.c_customer_id) AS customer_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) FILTER (WHERE p.p_channel_tv = 'Y') AS avg_tv_promo_cost,
    SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) AS email_promo_cnt,
    MAX(d_end.d_year) - MIN(d_store.d_year) AS promo_store_year_gap
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_store.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_store.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_shipto
    ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
WHERE s.s_country = 'United States'
  AND p.p_discount_active = 'Y'
  AND cd.cd_gender IS NOT NULL
GROUP BY
    s.s_city,
    s.s_state,
    cd.cd_gender,
    cd.cd_marital_status,
    DATE_TRUNC('month', d_shipto.d_date)
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY total_promo_cost DESC
LIMIT 100
