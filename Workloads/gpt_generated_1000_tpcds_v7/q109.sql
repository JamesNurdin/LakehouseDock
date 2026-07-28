WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        s.s_store_name,
        p.p_promo_name,
        d.d_year,
        regexp_extract(p.p_promo_name, '(?i)(sale|discount)', 1) AS promo_type,
        concat('Store_', s.s_store_id) AS store_label,
        substring(s.s_store_name, 1, 5) AS store_name_prefix
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(p.p_promo_name, '(?i)sale|discount')
      AND s.s_store_name LIKE '%Market%'
)
SELECT
    store_label,
    store_name_prefix,
    promo_type,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(ss_net_profit) AS avg_net_profit
FROM filtered_sales
GROUP BY
    store_label,
    store_name_prefix,
    promo_type
ORDER BY total_net_profit DESC
LIMIT 100
