WITH sales_agg AS (
   SELECT
       i.i_item_sk,
       i.i_item_id,
       s.s_store_id,
       SUM(ss.ss_net_paid) AS net_paid,
       SUM(ss.ss_quantity) AS quantity,
       (
         SELECT SUM(ss2.ss_quantity)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = i.i_item_sk
       ) AS total_quantity_all_stores
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE ss.ss_net_paid > 0
   GROUP BY GROUPING SETS (
       (i.i_item_sk, i.i_item_id, s.s_store_id),
       (i.i_item_sk, i.i_item_id),
       ()
   )
),
catalog_sales_agg AS (
   SELECT
       i.i_item_sk,
       i.i_item_id,
       cp.cp_catalog_page_id,
       SUM(cs.cs_net_paid) AS net_paid,
       SUM(cs.cs_quantity) AS quantity,
       (
         SELECT SUM(cs2.cs_quantity)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = i.i_item_sk
       ) AS total_quantity_all_catalog
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cs.cs_net_paid > 0
   GROUP BY GROUPING SETS (
       (i.i_item_sk, i.i_item_id, cp.cp_catalog_page_id),
       (i.i_item_sk, i.i_item_id),
       ()
   )
),
sales_union AS (
   SELECT 'store'   AS source,
          i_item_sk,
          i_item_id,
          s_store_id          AS location_id,
          net_paid,
          quantity,
          total_quantity_all_stores AS total_quantity_all
   FROM sales_agg
   UNION ALL
   SELECT 'catalog' AS source,
          i_item_sk,
          i_item_id,
          cp_catalog_page_id AS location_id,
          net_paid,
          quantity,
          total_quantity_all_catalog AS total_quantity_all
   FROM catalog_sales_agg
),
returns_agg AS (
   SELECT
       i.i_item_sk,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_return_quantity) AS total_return_qty
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   GROUP BY i.i_item_sk
),
full_join AS (
   SELECT
       su.source,
       su.i_item_sk,
       su.i_item_id,
       su.location_id,
       su.net_paid,
       su.quantity,
       ra.total_return_amount,
       ra.total_return_qty
   FROM sales_union su
   FULL OUTER JOIN returns_agg ra
     ON su.i_item_sk = ra.i_item_sk
)
SELECT
   fj.source,
   fj.i_item_sk,
   fj.i_item_id,
   fj.location_id,
   fj.net_paid,
   fj.quantity,
   fj.total_return_amount,
   fj.total_return_qty
FROM full_join fj
WHERE fj.i_item_sk NOT IN (
        SELECT p_i.p_item_sk
        FROM promotion p_i
        WHERE p_i.p_discount_active = 'Y'
      )
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = fj.i_item_sk
          AND sr.sr_return_quantity > 0
      )
ORDER BY fj.source, fj.i_item_sk
