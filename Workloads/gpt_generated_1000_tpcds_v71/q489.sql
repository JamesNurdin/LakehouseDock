WITH cat_agg AS (
   SELECT
       cp.cp_catalog_page_id AS page_id,
       cp.cp_type AS page_type,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_net_profit) AS total_net_profit,
       CASE
           WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH'
           WHEN SUM(cs.cs_net_profit) > 0 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS profit_bucket,
       COUNT(*) AS txn_cnt,
       cp.cp_type || '_' || CASE
                               WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH'
                               WHEN SUM(cs.cs_net_profit) > 0 THEN 'MEDIUM'
                               ELSE 'LOW'
                           END AS page_summary
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE regexp_like(cp.cp_description, '.*premium.*')
     AND cp.cp_catalog_page_id LIKE 'AAAAA%'
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = cs.cs_promo_sk
           AND regexp_extract(p.p_promo_name, '(\\w+)_PROMO', 1) = 'SPRING'
     )
   GROUP BY cp.cp_catalog_page_id, cp.cp_type
),
web_agg AS (
   SELECT
       wp.wp_url AS page_id,
       'WEB' AS page_type,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_net_profit) AS total_net_profit,
       CASE
           WHEN SUM(ws.ws_net_profit) > 5000 THEN 'HIGH'
           WHEN SUM(ws.ws_net_profit) > 0 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS profit_bucket,
       COUNT(*) AS txn_cnt,
       'WEB' || '_' || CASE
                           WHEN SUM(ws.ws_net_profit) > 5000 THEN 'HIGH'
                           WHEN SUM(ws.ws_net_profit) > 0 THEN 'MEDIUM'
                           ELSE 'LOW'
                       END AS page_summary
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE regexp_like(wp.wp_url, '^https?://.*?/sale')
     AND wp.wp_type LIKE '%landing%'
   GROUP BY wp.wp_url
)
SELECT combined.page_id,
       combined.page_type,
       combined.total_net_paid,
       combined.profit_bucket,
       combined.txn_cnt,
       combined.page_summary
FROM (
   SELECT page_id, page_type, total_net_paid, profit_bucket, txn_cnt, page_summary
   FROM cat_agg
   UNION ALL
   SELECT page_id, page_type, total_net_paid, profit_bucket, txn_cnt, page_summary
   FROM web_agg
) AS combined
WHERE combined.total_net_paid > (
   SELECT AVG(inner_total)
   FROM (
       SELECT total_net_paid AS inner_total FROM cat_agg
       UNION ALL
       SELECT total_net_paid FROM web_agg
   ) avg_sub
)
ORDER BY combined.total_net_paid DESC
LIMIT 100
