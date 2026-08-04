WITH
  cs_agg AS (
    SELECT
      cs.cs_promo_sk,
      SUM(cs.cs_net_profit)               AS cs_total_profit,
      SUM(cs.cs_ext_list_price)           AS cs_total_list_price,
      COUNT(*)                            AS cs_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_list_price > 2000
      AND p.p_channel_event = 'N'
      AND p.p_channel_demo = 'N'
    GROUP BY cs.cs_promo_sk
  ),

  ss_agg AS (
    SELECT
      ss.ss_promo_sk,
      SUM(ss.ss_net_profit)               AS ss_total_profit,
      SUM(ss.ss_ext_list_price)           AS ss_total_list_price,
      COUNT(*)                            AS ss_cnt
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_tax < 100
      AND p.p_channel_demo = 'N'
    GROUP BY ss.ss_promo_sk
  ),

  combined AS (
    SELECT
      COALESCE(cs.cs_promo_sk, ss.ss_promo_sk) AS promo_sk,
      cs.cs_total_profit,
      ss.ss_total_profit,
      cs.cs_total_list_price,
      ss.ss_total_list_price,
      cs.cs_cnt,
      ss.ss_cnt
    FROM cs_agg cs
    FULL OUTER JOIN ss_agg ss
      ON cs.cs_promo_sk = ss.ss_promo_sk
  ),

  filtered AS (
    SELECT
      c.promo_sk,
      COALESCE(c.cs_total_profit, 0) + COALESCE(c.ss_total_profit, 0) AS total_profit,
      COALESCE(c.cs_total_list_price, 0) + COALESCE(c.ss_total_list_price, 0) AS total_list_price,
      COALESCE(c.cs_cnt, 0) + COALESCE(c.ss_cnt, 0)               AS total_cnt,
      CASE
        WHEN COALESCE(c.cs_total_profit, 0) + COALESCE(c.ss_total_profit, 0) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
      END                                                          AS profit_category,
      pi.promo_item_cnt
    FROM combined c
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS promo_item_cnt
      FROM promotion p
      WHERE p.p_promo_sk = c.promo_sk
    ) pi ON TRUE
    WHERE NOT EXISTS (
      SELECT 1
      FROM catalog_sales cs2
      WHERE cs2.cs_promo_sk = c.promo_sk
        AND cs2.cs_quantity > 10
    )
  ),

  promo_stub AS (
    SELECT
      p.p_promo_sk                     AS promo_sk,
      0.0                              AS total_profit,
      0.0                              AS total_list_price,
      0                                AS total_cnt,
      'NO_DATA'                        AS profit_category,
      pi2.promo_item_cnt
    FROM promotion p
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS promo_item_cnt
      FROM promotion p2
      WHERE p2.p_promo_sk = p.p_promo_sk
    ) pi2 ON TRUE
    WHERE p.p_channel_event = 'N'
  ),

  unioned AS (
    SELECT * FROM filtered
    UNION DISTINCT
    SELECT * FROM promo_stub
  )
SELECT
  profit_category,
  AVG(total_profit)   AS avg_total_profit,
  SUM(total_cnt)      AS sum_total_cnt
FROM unioned
GROUP BY profit_category
HAVING SUM(total_cnt) > 5
ORDER BY avg_total_profit DESC
LIMIT 100
