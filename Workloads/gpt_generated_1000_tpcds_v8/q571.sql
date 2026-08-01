WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),

store_sales_right AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_sk,
        p.p_promo_name,
        COALESCE(promo_ex.promo_num, '') AS promo_num,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS txn_cnt
    FROM sampled_store_sales ss
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
        SELECT regexp_extract(p.p_promo_name, '\\d+', 0) AS promo_num
    ) promo_ex ON TRUE
    WHERE p.p_promo_name IS NULL
          OR regexp_like(p.p_promo_name, '^Promo[0-9]+$')
    GROUP BY s.s_store_id, s.s_store_name, p.p_promo_sk, p.p_promo_name, promo_ex.promo_num
),

web_sales_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),

web_sales_agg AS (
    SELECT
        wp.wp_url,
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS web_total_net_paid,
        COUNT(*) AS web_txn_cnt
    FROM web_sales_sample ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE wp.wp_url LIKE '%promo%'
      AND regexp_like(wp.wp_url, '^https?://')
    GROUP BY wp.wp_url, p.p_promo_sk, p.p_promo_name
),

promo_intersect AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, 'Discount')
    INTERSECT
    SELECT DISTINCT ws.ws_promo_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
),

final AS (
    SELECT
        COALESCE(ssr.s_store_id, 'NO_STORE') AS store_id,
        ssr.s_store_name,
        ssr.p_promo_name AS store_promo_name,
        ssr.promo_num,
        ssr.total_net_paid,
        ssr.txn_cnt,
        CONCAT(ssr.s_store_name, ' - ', ssr.promo_num) AS store_promo_label,
        wa.wp_url,
        wa.p_promo_name AS web_promo_name,
        wa.web_total_net_paid,
        wa.web_txn_cnt
    FROM store_sales_right ssr
    FULL OUTER JOIN web_sales_agg wa
        ON ssr.p_promo_sk = wa.p_promo_sk
    WHERE ssr.p_promo_sk IS NULL
          OR ssr.p_promo_sk IN (SELECT p_promo_sk FROM promo_intersect)
)

SELECT
    store_id,
    s_store_name,
    store_promo_name,
    promo_num,
    total_net_paid,
    txn_cnt,
    store_promo_label,
    wp_url,
    web_promo_name,
    web_total_net_paid,
    web_txn_cnt,
    (SELECT AVG(total_net_paid) FROM store_sales_right) AS avg_store_net_paid
FROM final
ORDER BY total_net_paid DESC NULLS LAST
LIMIT 100
