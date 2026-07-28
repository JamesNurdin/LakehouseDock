WITH distinct_managers AS (
   SELECT DISTINCT s.s_manager
   FROM store s
   WHERE regexp_like(s.s_manager, '^A.*n$')
),
store_profit AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_manager,
       d.d_year,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY s.s_store_sk, s.s_store_name, s.s_manager, d.d_year
),
catalog_profit AS (
   SELECT
       cp.cp_catalog_page_sk,
       cp.cp_description,
       cp.cp_type,
       d.d_year,
       SUM(cs.cs_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY cp.cp_catalog_page_sk, cp.cp_description, cp.cp_type, d.d_year
)
SELECT *
FROM (
   SELECT
       sp.s_store_name AS entity_name,
       'Store' AS entity_type,
       sp.d_year,
       sp.total_net_profit,
       CASE WHEN sp.total_net_profit > (SELECT AVG(total_net_profit) FROM store_profit) THEN 'High' ELSE 'Low' END AS profit_category,
       CONCAT(sp.s_store_name, ' (', CAST(sp.d_year AS VARCHAR), ')') AS entity_label,
       (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_store_sk = sp.s_store_sk AND sr.sr_net_loss > 0) AS loss_return_count
   FROM store_profit sp
   WHERE sp.s_store_name LIKE '%Market%'
     AND sp.s_manager IN (SELECT s_manager FROM distinct_managers)
     AND EXISTS (
         SELECT 1
         FROM store_returns sr
         JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
         WHERE sr.sr_store_sk = sp.s_store_sk
           AND regexp_like(r.r_reason_desc, 'defect')
     )
   UNION ALL
   SELECT
       cp.cp_description AS entity_name,
       'Catalog' AS entity_type,
       cp.d_year,
       cp.total_net_profit,
       CASE WHEN cp.total_net_profit > (SELECT AVG(total_net_profit) FROM catalog_profit) THEN 'High' ELSE 'Low' END AS profit_category,
       CONCAT(cp.cp_description, ' (', CAST(cp.d_year AS VARCHAR), ')') AS entity_label,
       NULL AS loss_return_count
   FROM catalog_profit cp
   WHERE regexp_like(cp.cp_description, '^.*[A-Z]{2}.*$')
     AND cp.cp_type LIKE 'PROMO%'
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
