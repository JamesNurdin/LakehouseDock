WITH page_sales AS (
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_type,
       w.w_warehouse_name,
       w.w_zip,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS transaction_cnt,
       MAX(cs.cs_sold_date_sk) AS last_sold_date_sk
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE regexp_like(cp.cp_description, '(?i)discount')
     AND cp.cp_type LIKE 'monthly%'
   GROUP BY cp.cp_catalog_page_id, cp.cp_type, w.w_warehouse_name, w.w_zip
)
SELECT
   DISTINCT ps.cp_catalog_page_id,
   ps.cp_type,
   ps.w_warehouse_name,
   ps.w_zip,
   ps.total_profit,
   ps.transaction_cnt,
   ROW_NUMBER() OVER (ORDER BY ps.total_profit DESC) AS profit_rank,
   CONCAT('WH-', ps.w_warehouse_name) AS warehouse_label,
   SUBSTRING(ps.w_zip, 1, 3) AS zip_prefix
FROM page_sales ps
WHERE regexp_extract(ps.w_warehouse_name, '[A-Za-z]+') IS NOT NULL
ORDER BY ps.total_profit DESC
LIMIT 100
