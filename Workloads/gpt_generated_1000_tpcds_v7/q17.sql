WITH catalog_agg AS (
   SELECT
       i.i_item_sk AS item_sk,
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       'catalog' AS return_source,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_return_quantity) AS total_quantity,
       CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cr.cr_returned_date_sk BETWEEN 2450843 AND 2450948
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
store_agg AS (
   SELECT
       i.i_item_sk AS item_sk,
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       'store' AS return_source,
       SUM(sr.sr_return_amt) AS total_return_amount,
       SUM(sr.sr_return_quantity) AS total_quantity,
       CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2450843 AND 2450948
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
combined AS (
   SELECT * FROM catalog_agg
   UNION ALL
   SELECT * FROM store_agg
)
SELECT
   c.item_sk,
   c.item_id,
   c.product_name,
   c.return_source,
   c.total_return_amount,
   c.total_quantity,
   c.amount_category,
   ROW_NUMBER() OVER (PARTITION BY c.return_source ORDER BY c.total_return_amount DESC) AS rank_by_source
FROM combined c
WHERE NOT EXISTS (
   SELECT 1 FROM promotion p WHERE p.p_item_sk = c.item_sk
)
ORDER BY c.return_source, rank_by_source
LIMIT 100
