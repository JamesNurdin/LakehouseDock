WITH promo_catalog AS (
    SELECT
        p.p_promo_sk,
        w.word AS promo_word,
        SUM(cs.cs_net_paid) AS total_cs_sales
    FROM promotion p
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    CROSS JOIN UNNEST(split(p.p_promo_name, ' ')) AS w(word)
    WHERE p.p_channel_radio = 'N'
    GROUP BY p.p_promo_sk, w.word
),
promo_store AS (
    SELECT
        p.p_promo_sk,
        w.word AS promo_word,
        SUM(ss.ss_net_paid) AS total_ss_sales
    FROM promotion p
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    CROSS JOIN UNNEST(split(p.p_promo_name, ' ')) AS w(word)
    WHERE p.p_channel_demo = 'N'
    GROUP BY p.p_promo_sk, w.word
),
promo_intersection AS (
    SELECT p.p_promo_sk, p.promo_word
    FROM promo_catalog p
    INTERSECT
    SELECT s.p_promo_sk, s.promo_word
    FROM promo_store s
)
SELECT pi.p_promo_sk,
       pi.promo_word
FROM promo_intersection pi
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    JOIN warehouse w ON cs2.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs2.cs_promo_sk = pi.p_promo_sk
      AND w.w_county = 'Ziebach County'
)
ORDER BY pi.p_promo_sk, pi.promo_word
LIMIT 100
