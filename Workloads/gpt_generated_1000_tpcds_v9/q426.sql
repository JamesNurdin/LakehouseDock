WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        store.s_state,
        store.s_store_name,
        store.s_store_id,
        promotion.p_promo_name,
        promotion.p_channel_tv,
        regexp_extract(store.s_store_id, '(\\d+)', 1) AS store_id_number,
        regexp_extract(promotion.p_promo_name, '([A-Za-z]+)', 1) AS promo_alpha_part
    FROM store_sales AS ss
    JOIN store ON ss.ss_store_sk = store.s_store_sk
    JOIN promotion ON ss.ss_promo_sk = promotion.p_promo_sk
    WHERE regexp_like(store.s_store_name, '(?i)market')
      AND regexp_like(promotion.p_promo_name, '(?i)discount|sale')
      AND promotion.p_channel_tv LIKE 'Y%'
)
SELECT
    CASE WHEN SUM(fs.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    fs.s_state,
    fs.p_promo_name,
    COUNT(DISTINCT fs.ss_ticket_number) AS transaction_count,
    SUM(fs.ss_quantity) AS total_quantity,
    SUM(fs.ss_net_paid) AS total_net_paid,
    SUM(fs.ss_net_profit) AS total_net_profit,
    CONCAT(COALESCE(fs.s_state, 'All States'), ': ', COALESCE(fs.p_promo_name, 'All Promotions')) AS state_promo_label,
    MIN(fs.store_id_number) AS sample_store_id_number,
    MIN(fs.promo_alpha_part) AS sample_promo_alpha_part
FROM filtered_sales AS fs
GROUP BY ROLLUP(fs.s_state, fs.p_promo_name)
LIMIT 100
