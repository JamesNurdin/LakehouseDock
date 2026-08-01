WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d.d_date AS start_date,
        CASE
            WHEN p.p_promo_name LIKE '%able%' THEN 'ContainsAble'
            WHEN regexp_like(p.p_promo_name, 'tion$') THEN 'EndsWithTion'
            ELSE 'Other'
        END AS promo_category,
        CONCAT(UPPER(p.p_promo_name), '_', CAST(p.p_promo_sk AS VARCHAR)) AS promo_key
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE regexp_like(p.p_promo_name, '[aeiou]{2,}')
      AND p.p_channel_catalog = 'N'
),
agg_sales AS (
    SELECT
        pf.p_promo_sk AS p_sk,
        pf.p_promo_name AS p_name,
        pf.start_date,
        pf.promo_category,
        pf.promo_key,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid,
        MAX(
            CASE
                WHEN wp.wp_url IS NOT NULL THEN regexp_extract(wp.wp_url, '(promo[0-9]+)', 1)
                ELSE NULL
            END
        ) AS extracted_promo_code
    FROM promo_filtered pf
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = pf.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN web_page wp2 ON ws2.ws_web_page_sk = wp2.wp_web_page_sk
        WHERE ws2.ws_promo_sk = pf.p_promo_sk
          AND wp2.wp_url LIKE '%promo%'
          AND regexp_extract(wp2.wp_url, '(promo[0-9]+)', 1) IS NOT NULL
    )
    GROUP BY
        pf.p_promo_sk,
        pf.p_promo_name,
        pf.start_date,
        pf.promo_category,
        pf.promo_key
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num,
    p_sk,
    p_name,
    start_date,
    promo_category,
    promo_key,
    total_net_paid,
    CASE WHEN total_net_paid > 10000 THEN 'High' ELSE 'Low' END AS revenue_level,
    extracted_promo_code
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 100
