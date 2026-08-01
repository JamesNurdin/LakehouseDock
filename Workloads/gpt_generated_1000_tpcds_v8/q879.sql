WITH
store_ret AS (
   SELECT
       sr.sr_returned_date_sk,
       sr.sr_item_sk,
       sr.sr_store_sk,
       sr.sr_return_quantity,
       d.d_year,
       i.i_category,
       i.i_color
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = sr.sr_store_sk AND s.s_state = 'CA')
),
catalog_ret AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_item_sk,
       cr.cr_return_quantity,
       d.d_year,
       i.i_category,
       i.i_color
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
combined AS (
   SELECT
       COALESCE(sr.sr_returned_date_sk, cr.cr_returned_date_sk) AS date_sk,
       COALESCE(sr.sr_item_sk, cr.cr_item_sk) AS item_sk,
       COALESCE(sr.d_year, cr.d_year) AS year,
       COALESCE(sr.i_category, cr.i_category) AS category,
       COALESCE(sr.i_color, cr.i_color) AS color,
       COALESCE(sr.sr_return_quantity, 0) + COALESCE(cr.cr_return_quantity, 0) AS total_qty,
       (SELECT max(d2.d_year) FROM date_dim d2) AS max_year
   FROM store_ret sr
   FULL OUTER JOIN catalog_ret cr
        ON sr.sr_returned_date_sk = cr.cr_returned_date_sk
       AND sr.sr_item_sk = cr.cr_item_sk
   LEFT JOIN LATERAL (
        SELECT sum(COALESCE(sr.sr_return_quantity, 0) + COALESCE(cr.cr_return_quantity, 0)) AS sum_qty
   ) l ON true
),
unioned AS (
   SELECT
       year,
       category,
       sum(total_qty) AS qty
   FROM combined
   GROUP BY GROUPING SETS ((year, category), (year), ())
   UNION
   SELECT
       year,
       category,
       sum(total_qty) * 1.05 AS qty
   FROM combined
   WHERE color = 'yellow'
   GROUP BY year, category
),
missing_items AS (
   SELECT cs.cs_item_sk AS item_sk
   FROM catalog_sales cs
   EXCEPT
   SELECT cr.cr_item_sk
   FROM catalog_returns cr
)
SELECT
   u.year,
   u.category,
   u.qty,
   NULL AS item_sk
FROM unioned u
UNION
SELECT
   NULL AS year,
   NULL AS category,
   NULL AS qty,
   mi.item_sk
FROM missing_items mi
ORDER BY year DESC NULLS LAST, qty DESC NULLS LAST
LIMIT 100
