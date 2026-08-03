WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        t.t_hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(p.p_promo_name, '.*Discount.*')
      AND c.c_email_address LIKE '%@example.com'
      AND substring(c.c_last_name, 1, 1) = 'S'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        t.t_hour
)
SELECT
    row_number() OVER (ORDER BY total_net_paid DESC) AS row_num,
    s_store_id,
    s_store_name,
    p_promo_name,
    t_hour,
    total_net_paid,
    sales_cnt,
    concat(s_store_name, ' - ', p_promo_name) AS store_promo
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
