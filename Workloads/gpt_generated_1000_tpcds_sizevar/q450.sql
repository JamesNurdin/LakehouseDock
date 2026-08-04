WITH cs AS (
   SELECT 
      cs.cs_promo_sk AS promo_sk,
      cs.cs_ship_mode_sk AS ship_mode_sk,
      CAST(NULL AS integer) AS hd_demo_sk,
      SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
      COUNT(*) AS cnt,
      'catalog' AS source
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_net_paid_inc_ship > (
         SELECT AVG(cs2.cs_net_paid_inc_ship)
         FROM catalog_sales cs2
   )
   GROUP BY GROUPING SETS (
      (cs.cs_promo_sk, cs.cs_ship_mode_sk),
      (cs.cs_ship_mode_sk),
      (cs.cs_promo_sk),
      ()
   )
),
ss AS (
   SELECT 
      ss.ss_promo_sk AS promo_sk,
      CAST(NULL AS integer) AS ship_mode_sk,
      ss.ss_hdemo_sk AS hd_demo_sk,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS cnt,
      'store' AS source
   FROM store_sales ss
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_net_paid > 1000
     AND ss.ss_promo_sk IN (
         SELECT p2.p_promo_sk
         FROM promotion p2
         WHERE p2.p_discount_active = 'Y'
     )
   GROUP BY GROUPING SETS (
      (ss.ss_promo_sk, ss.ss_hdemo_sk),
      (ss.ss_hdemo_sk),
      (ss.ss_promo_sk),
      ()
   )
),
full_join AS (
   SELECT 
      COALESCE(cs.promo_sk, ss.promo_sk) AS promo_sk,
      cs.ship_mode_sk,
      ss.hd_demo_sk,
      cs.total_net_paid AS cs_total_net_paid,
      ss.total_net_paid AS ss_total_net_paid,
      cs.cnt AS cs_cnt,
      ss.cnt AS ss_cnt
   FROM cs
   FULL OUTER JOIN ss ON cs.promo_sk = ss.promo_sk
),
union_part AS (
   SELECT 
      promo_sk,
      ship_mode_sk,
      hd_demo_sk,
      cs_total_net_paid AS total_net_paid,
      cs_cnt AS cnt,
      'catalog' AS source
   FROM full_join
   WHERE cs_total_net_paid IS NOT NULL
   UNION ALL
   SELECT 
      promo_sk,
      ship_mode_sk,
      hd_demo_sk,
      ss_total_net_paid AS total_net_paid,
      ss_cnt AS cnt,
      'store' AS source
   FROM full_join
   WHERE ss_total_net_paid IS NOT NULL
)
SELECT 
   up.promo_sk,
   up.ship_mode_sk,
   up.hd_demo_sk,
   up.total_net_paid,
   up.cnt,
   up.source
FROM union_part up
ORDER BY up.total_net_paid DESC
LIMIT 100
