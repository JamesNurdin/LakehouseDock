WITH target_stores AS (
    SELECT s.s_store_sk
    FROM store s
    WHERE s.s_county LIKE '%County'
    EXCEPT
    SELECT s.s_store_sk
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, 'Clearance')
      AND s.s_county LIKE '%County'
),
store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        MAX(CAST(regexp_extract(p.p_promo_name, '(\\d+)%') AS DOUBLE)) AS max_discount_pct
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
    WHERE s.s_store_sk IN (SELECT s_store_sk FROM target_stores)
    GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state
),
profit_band AS (
    SELECT *
    FROM (VALUES
        ('Low', 0, 10000),
        ('Medium', 10000.01, 50000),
        ('High', 50000.01, 1000000)
    ) AS t(band_label, low_bound, high_bound)
)
SELECT
    CONCAT(sa.s_store_name, ' - ', sa.s_city) AS store_full_name,
    sa.s_state,
    sa.total_net_profit,
    pb.band_label,
    COALESCE(sa.max_discount_pct, 0) AS max_discount_pct
FROM store_agg sa
CROSS JOIN profit_band pb
WHERE sa.total_net_profit BETWEEN pb.low_bound AND pb.high_bound
ORDER BY sa.total_net_profit DESC
LIMIT 100
