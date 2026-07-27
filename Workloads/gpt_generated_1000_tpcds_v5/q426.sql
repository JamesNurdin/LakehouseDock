WITH filtered_items AS (
   SELECT i_item_sk, i_item_id, i_product_name
   FROM item
   WHERE i_manufact_id IN (
       SELECT i_manufact_id
       FROM item
       WHERE i_size = 'large'
   )
)

SELECT
   i_item_id,
   i_product_name,
   metric,
   source
FROM (
   SELECT
      fi.i_item_id,
      fi.i_product_name,
      SUM(cr.cr_return_amount) AS metric,
      'catalog_return' AS source
   FROM catalog_returns cr
   JOIN filtered_items fi
     ON cr.cr_item_sk = fi.i_item_sk
   JOIN customer_demographics cd
     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_dep_employed_count > 2
   GROUP BY fi.i_item_id, fi.i_product_name
) AS cr_sub
UNION ALL
SELECT
   i_item_id,
   i_product_name,
   metric,
   source
FROM (
   SELECT
      fi.i_item_id,
      fi.i_product_name,
      SUM(ws.ws_net_paid_inc_ship_tax) AS metric,
      'web_sales' AS source
   FROM web_sales ws
   JOIN filtered_items fi
     ON ws.ws_item_sk = fi.i_item_sk
   JOIN customer_demographics cd
     ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_dep_employed_count > 2
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr2
         WHERE cr2.cr_item_sk = ws.ws_item_sk
           AND cr2.cr_return_amount > 0
     )
   GROUP BY fi.i_item_id, fi.i_product_name
) AS ws_sub
ORDER BY metric DESC
LIMIT 100
