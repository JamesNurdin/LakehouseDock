WITH sales_promo AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        p.p_promo_name,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid_inc_tax,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(p.p_promo_name, '(?i)Holiday')
      AND s.s_city LIKE 'A%'
)
SELECT
    s_store_id,
    CONCAT(s_city, ', ', s_state) AS store_location,
    p_promo_name,
    CASE
        WHEN ss_ext_discount_amt > 1000 THEN 'High'
        WHEN ss_ext_discount_amt > 100 THEN 'Medium'
        ELSE 'Low'
    END AS discount_category,
    SUM(ss_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    MAX(ib_upper_bound) AS max_income_upper_bound
FROM sales_promo
GROUP BY
    s_store_id,
    CONCAT(s_city, ', ', s_state),
    p_promo_name,
    CASE
        WHEN ss_ext_discount_amt > 1000 THEN 'High'
        WHEN ss_ext_discount_amt > 100 THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY total_net_paid DESC
LIMIT 100
