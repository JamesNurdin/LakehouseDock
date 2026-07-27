WITH promo_filtered AS (
    SELECT
        p_promo_sk,
        p_promo_id,
        p_promo_name,
        p_channel_email,
        regexp_extract(p_promo_name, '(\\d+)', 1) AS promo_number,
        concat(p_promo_id, '-', p_promo_name) AS promo_key
    FROM promotion
    WHERE regexp_like(p_promo_name, '(?i)discount')
      AND p_channel_email = 'N'
      AND p_promo_name LIKE '%Summer%'
)
SELECT
    pf.p_promo_id,
    pf.promo_key,
    cd.cd_gender,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    SUM(ss.ss_coupon_amt) AS total_coupon_amount
FROM store_sales ss
JOIN promo_filtered pf
    ON ss.ss_promo_sk = pf.p_promo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
GROUP BY pf.p_promo_id, pf.promo_key, cd.cd_gender
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
