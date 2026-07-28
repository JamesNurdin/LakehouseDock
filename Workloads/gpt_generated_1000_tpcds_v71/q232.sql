WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        p.p_channel_tv,
        s.s_city,
        cd.cd_gender,
        SUM(ss.ss_net_paid)               AS total_net_paid,
        SUM(ss.ss_net_profit)             AS total_net_profit,
        COUNT(*)                           AS sales_cnt,
        AVG(ss.ss_net_profit)             AS avg_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND s.s_street_name LIKE '%Street%'
    GROUP BY ROLLUP (s.s_state, p.p_channel_tv, cd.cd_gender, s.s_store_id, p.p_promo_id, s.s_city)
)
SELECT
    sa.s_state,
    sa.p_channel_tv,
    CASE WHEN sa.cd_gender = 'M' THEN 'Male' ELSE 'Other' END               AS gender_group,
    sa.s_store_id,
    sa.p_promo_id,
    CONCAT(sa.s_city, '-', sa.p_promo_id)                                      AS city_promo,
    regexp_extract(sa.p_promo_id, '([A-Z]+)', 1)                               AS promo_prefix,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.sales_cnt,
    sa.avg_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sa.s_state ORDER BY sa.total_net_profit DESC) AS rank_within_state,
    CASE WHEN sa.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_agg) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM store s2
    JOIN store_sales ss2 ON ss2.ss_store_sk = s2.s_store_sk
    WHERE s2.s_store_id = sa.s_store_id
      AND ss2.ss_quantity > 10
)
ORDER BY sa.s_state, rank_within_state
LIMIT 100
