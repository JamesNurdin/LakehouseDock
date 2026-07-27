WITH promo_stats AS (
    SELECT
        p.p_promo_sk,
        AVG(ss.ss_net_paid) AS avg_store_net_paid,
        MAX(ss.ss_net_paid) AS max_store_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_country = 'United States'
      AND ss.ss_ext_tax > 30
    GROUP BY p.p_promo_sk
)
SELECT
    'store' AS source,
    ss.ss_sold_date_sk AS date_sk,
    p.p_promo_id,
    s.s_store_name,
    ss.ss_net_paid,
    ps.avg_store_net_paid
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN promo_stats ps ON p.p_promo_sk = ps.p_promo_sk
WHERE ss.ss_net_paid > (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_promo_sk = p.p_promo_sk
    )
  AND s.s_state = 'CA'

UNION ALL

SELECT
    'catalog' AS source,
    cs.cs_sold_date_sk AS date_sk,
    p.p_promo_id,
    cc.cc_name,
    cs.cs_net_paid,
    NULL AS avg_store_net_paid
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE cs.cs_net_paid > 0
  AND cc.cc_country = 'United States'
  AND cs.cs_ext_discount_amt > 20

ORDER BY date_sk DESC, source
LIMIT 100
