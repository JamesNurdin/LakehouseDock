WITH combined AS (
    SELECT src, id, total_net_paid, category, tag
    FROM (
        SELECT
            'store' AS src,
            s.s_store_id AS id,
            SUM(ss.ss_net_paid) AS total_net_paid,
            CASE WHEN s.s_geography_class = 'Unknown' THEN 'Other' ELSE s.s_geography_class END AS category,
            regexp_extract(s.s_market_desc, '(\\w+)', 1) AS tag
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND s.s_market_desc LIKE '%Local%'
        GROUP BY s.s_store_id, s.s_geography_class, s.s_market_desc
    )
    UNION ALL
    SELECT src, id, total_net_paid, category, tag
    FROM (
        SELECT
            'return' AS src,
            s.s_store_id AS id,
            -SUM(sr.sr_return_amt) AS total_net_paid,
            CASE WHEN regexp_like(r.r_reason_desc, '.*damage.*') THEN 'Damage' ELSE 'Other' END AS category,
            CONCAT('Return_', CAST(s.s_store_sk AS VARCHAR)) AS tag
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND r.r_reason_desc LIKE '%customer%'
        GROUP BY s.s_store_id, s.s_store_sk, r.r_reason_desc
    )
)
SELECT
    src,
    id,
    total_net_paid,
    category,
    tag,
    ROW_NUMBER() OVER (PARTITION BY src ORDER BY total_net_paid DESC) AS rank_within_src
FROM combined
ORDER BY total_net_paid DESC, src
LIMIT 100
