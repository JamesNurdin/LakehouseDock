WITH store_ret_agg AS (
   SELECT
       s.s_store_id,
       s.s_store_name,
       t.t_hour,
       SUM(sr.sr_net_loss) AS total_net_loss,
       COUNT(*) AS returns_cnt
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE regexp_like(r.r_reason_desc, '(?i)damage')
     AND s.s_store_name LIKE '%Warehouse%'
     AND s.s_store_sk IN (SELECT s_store_sk FROM store WHERE s_city LIKE 'San%')
   GROUP BY s.s_store_id, s.s_store_name, t.t_hour
),
catalog_ret_agg AS (
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_type,
       t.t_hour,
       SUM(cr.cr_net_loss) AS total_net_loss,
       COUNT(*) AS returns_cnt
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%Late%'
     AND regexp_extract(cp.cp_description, '[A-Z]{3,}', 1) = 'ABC'
   GROUP BY cp.cp_catalog_page_id, cp.cp_type, t.t_hour
)

SELECT *
FROM (
   SELECT
       'store' AS source_type,
       s_agg.s_store_id AS identifier,
       CONCAT(s_agg.s_store_name, ' (ID:', s_agg.s_store_id, ')') AS full_desc,
       s_agg.t_hour AS hour,
       s_agg.total_net_loss,
       s_agg.returns_cnt,
       (SELECT COUNT(*) FROM promotion p WHERE p.p_discount_active = 'Y') AS active_promo_cnt
   FROM store_ret_agg s_agg
   WHERE EXISTS (
       SELECT 1 FROM promotion p WHERE p.p_promo_name LIKE '%Discount%'
   )
   UNION ALL
   SELECT
       'catalog' AS source_type,
       c_agg.cp_catalog_page_id AS identifier,
       CONCAT(c_agg.cp_type, ' - ', c_agg.cp_catalog_page_id) AS full_desc,
       c_agg.t_hour AS hour,
       c_agg.total_net_loss,
       c_agg.returns_cnt,
       (SELECT COUNT(*) FROM promotion p WHERE p.p_discount_active = 'Y') AS active_promo_cnt
   FROM catalog_ret_agg c_agg
   WHERE c_agg.total_net_loss > (
       SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2
   )
) AS combined
ORDER BY source_type, total_net_loss DESC
LIMIT 100
