WITH sales_join AS (
    SELECT
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        c.c_salutation,
        cd.cd_education_status,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        s.s_store_name,
        s.s_state,
        p.p_discount_active
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE c.c_salutation = 'Mrs.'
      AND cd.cd_education_status = 'Advanced Degree'
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_lower_bound >= 50000
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
)
SELECT
    s_store_name,
    p_promo_name,
    cd_education_status,
    hd_buy_potential,
    CONCAT(CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) AS income_range,
    COUNT(*) AS transactions,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_ext_discount_amt) AS avg_discount_amount,
    MIN(ss_net_paid) AS min_net_paid,
    MAX(ss_net_paid) AS max_net_paid
FROM sales_join
GROUP BY
    s_store_name,
    p_promo_name,
    cd_education_status,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
