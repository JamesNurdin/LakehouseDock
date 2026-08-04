WITH
call_center_filtered AS (
   SELECT
      cc_call_center_sk,
      cc_name,
      cc_city,
      cc_manager,
      split(cc_manager, ' ') AS manager_name_parts,
      regexp_extract(cc_manager, '(\\w+)$') AS manager_last_name
   FROM call_center
   WHERE regexp_like(cc_name, 'Center$')
     AND cc_city LIKE 'A%'
),
store_filtered AS (
   SELECT
      s_store_sk,
      s_store_name,
      s_street_type
   FROM store
   WHERE regexp_like(s_street_type, '^St|^Way')
),
warehouse_ids_from_inventory AS (
   SELECT DISTINCT inv_warehouse_sk AS warehouse_sk
   FROM inventory
   WHERE inv_quantity_on_hand > 0
),
warehouse_ids_from_catalog AS (
   SELECT DISTINCT cs_warehouse_sk AS warehouse_sk
   FROM catalog_sales
   WHERE cs_ext_sales_price > 1000
),
warehouse_excluding AS (
   SELECT warehouse_sk FROM warehouse_ids_from_inventory
   EXCEPT
   SELECT warehouse_sk FROM warehouse_ids_from_catalog
),
warehouse_common AS (
   SELECT warehouse_sk FROM warehouse_ids_from_inventory
   INTERSECT
   SELECT warehouse_sk FROM warehouse_ids_from_catalog
),
sales_agg AS (
   SELECT
      w.w_warehouse_sk,
      w.w_warehouse_name,
      d.d_year,
      cs.cs_call_center_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN call_center_filtered cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year = 2001
   GROUP BY w.w_warehouse_sk, w.w_warehouse_name, d.d_year, cs.cs_call_center_sk
)
SELECT
   s.w_warehouse_name,
   s.d_year,
   s.total_sales,
   s.order_cnt,
   cc.cc_name,
   concat(cc.cc_name, ' - ', cc.cc_city) AS concat_name_city,
   cc.manager_last_name,
   COUNT(t.part) AS manager_name_word_count,
   substr(cc.cc_manager, 1, 10) AS manager_prefix,
   CASE WHEN wex.warehouse_sk IS NOT NULL THEN 'EXCLUDED' ELSE 'INCLUDED' END AS warehouse_status,
   CASE WHEN wcom.warehouse_sk IS NOT NULL THEN 'COMMON' ELSE 'NOT_COMMON' END AS common_status
FROM sales_agg s
JOIN call_center_filtered cc ON s.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse_excluding wex ON s.w_warehouse_sk = wex.warehouse_sk
LEFT JOIN warehouse_common wcom ON s.w_warehouse_sk = wcom.warehouse_sk
CROSS JOIN UNNEST(cc.manager_name_parts) AS t(part)
GROUP BY
   s.w_warehouse_name,
   s.d_year,
   s.total_sales,
   s.order_cnt,
   cc.cc_name,
   cc.cc_city,
   cc.manager_last_name,
   cc.cc_manager,
   wex.warehouse_sk,
   wcom.warehouse_sk
ORDER BY s.total_sales DESC
LIMIT 100
