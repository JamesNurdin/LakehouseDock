WITH agg AS (
   SELECT
       i.i_category,
       sm.sm_type,
       i.i_item_id,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_return_quantity) AS total_return_quantity
   FROM tpcds.catalog_returns cr
   JOIN tpcds.item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN tpcds.ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cr.cr_return_tax > 20
     AND cr.cr_store_credit < 500
     AND i.i_manager_id IN (18, 21, 34)
     AND i.i_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2002-01-01'
     AND sm.sm_type = 'EXPRESS'
   GROUP BY i.i_category, sm.sm_type, i.i_item_id
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY i_category, sm_type ORDER BY total_return_amount DESC) AS rn_category,
       ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS global_rn
   FROM agg
)
SELECT
   i_category,
   sm_type,
   i_item_id,
   total_return_amount,
   total_return_quantity,
   rn_category,
   global_rn
FROM ranked
WHERE rn_category <= 5
ORDER BY i_category, sm_type, rn_category
LIMIT 100
