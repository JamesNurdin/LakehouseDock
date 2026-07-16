SELECT
    p.p_promo_name,
    sd.d_year AS sold_year,
    sd.d_month_seq AS sold_month,
    s.s_state,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_paid_inc_tax - cs.cs_net_paid_inc_ship_tax) AS tax_ship_diff,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_ext_discount_amt ELSE 0 END) AS active_discount_sum,
    AVG(cs.cs_quantity) AS avg_quantity,
    ROUND(100 * SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_sales_price), 0), 2) AS profit_margin_pct,
    MIN(sd.d_date) AS first_sold_date,
    MAX(shd.d_date) AS last_ship_date,
    COUNT(*) FILTER (WHERE wp.wp_autogen_flag = 'Y') AS autogen_page_cnt,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN cs.cs_ext_sales_price ELSE 0 END) AS landing_sales_price_sum,
    DATE_DIFF('day', MAX(pstart.d_date), MAX(pend.d_date)) AS promo_duration_days
FROM catalog_sales cs
JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
JOIN date_dim shd ON cs.cs_ship_date_sk = shd.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim pstart ON p.p_start_date_sk = pstart.d_date_sk
JOIN date_dim pend ON p.p_end_date_sk = pend.d_date_sk
JOIN store s ON s.s_closed_date_sk = sd.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = sd.d_date_sk
JOIN date_dim wa ON wp.wp_access_date_sk = wa.d_date_sk
WHERE sd.d_year = 2022
  AND p.p_channel_email = 'Online'
  AND wp.wp_type IN ('Landing', 'Product')
GROUP BY
    p.p_promo_name,
    sd.d_year,
    sd.d_month_seq,
    s.s_state,
    wp.wp_type
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_net_paid DESC
LIMIT 50
