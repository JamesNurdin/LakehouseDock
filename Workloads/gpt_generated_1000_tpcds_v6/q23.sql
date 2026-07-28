WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        concat(p.p_promo_name, ':', p.p_promo_id) AS promo_full_name,
        regexp_extract(p.p_channel_details, '(\\w+)', 1) AS first_word_channel,
        CASE WHEN regexp_like(p.p_promo_name, '^a') THEN 'StartsWithA' ELSE 'Other' END AS name_category,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_promo_name LIKE '%a%'
    GROUP BY
        p.p_promo_sk,
        concat(p.p_promo_name, ':', p.p_promo_id),
        regexp_extract(p.p_channel_details, '(\\w+)', 1),
        CASE WHEN regexp_like(p.p_promo_name, '^a') THEN 'StartsWithA' ELSE 'Other' END,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    promo_full_name,
    first_word_channel,
    name_category,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_net_profit,
    sales_cnt,
    avg_net_profit,
    CASE
        WHEN total_net_profit > 100000 THEN 'High'
        WHEN total_net_profit > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_profit DESC) AS profit_rank_in_band
FROM promo_sales
ORDER BY total_net_profit DESC
LIMIT 100
