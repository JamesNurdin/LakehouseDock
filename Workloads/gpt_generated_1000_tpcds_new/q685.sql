WITH store_perf AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        CONCAT('Store_', CAST(s.s_store_sk AS VARCHAR)) AS store_key,
        REGEXP_EXTRACT(s.s_store_name, '^([A-Za-z]+)') AS store_prefix,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_net_profit) DESC) AS state_store_rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND REGEXP_LIKE(s.s_store_name, '^.*Center.*$')
      AND s.s_store_name LIKE '%Store%'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state
)
SELECT
    sp.s_store_name,
    sp.s_state,
    sp.total_net_profit,
    sp.distinct_customers,
    sp.distinct_items,
    sp.store_prefix,
    sp.state_store_rank,
    nb.bucket,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    COUNT(DISTINCT r.r_reason_id) AS distinct_reasons
FROM store_perf sp
CROSS JOIN (VALUES 1, 2, 3) AS nb(bucket)
LEFT JOIN store_sales ss2 ON ss2.ss_store_sk = sp.s_store_sk
LEFT JOIN promotion p ON ss2.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_store_sk = sp.s_store_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY
    sp.s_store_name,
    sp.s_state,
    sp.total_net_profit,
    sp.distinct_customers,
    sp.distinct_items,
    sp.store_prefix,
    sp.state_store_rank,
    nb.bucket
ORDER BY sp.total_net_profit DESC, sp.s_store_name
OFFSET 20 LIMIT 100
