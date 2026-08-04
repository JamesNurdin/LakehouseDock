WITH
  max_price AS (
    SELECT max(i_current_price) AS max_price
    FROM item
    WHERE i_brand = 'BrandX'
  ),
  catalog_subset AS (
    SELECT cs.cs_item_sk,
           cs.cs_ext_sales_price,
           cp.cp_type
    FROM (
      SELECT *
      FROM catalog_sales
      TABLESAMPLE BERNOULLI (5)
    ) cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  ),
  store_reason_subset AS (
    SELECT sr.sr_item_sk,
           sr.sr_return_amt,
           r.r_reason_desc
    FROM (
      SELECT *
      FROM store_returns
      TABLESAMPLE BERNOULLI (5)
    ) sr
    FULL OUTER JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
  ),
  inventory_subset AS (
    SELECT inv.inv_item_sk
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
  ),
  catalog_item_set AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 500
  ),
  common_items AS (
    SELECT item_sk FROM catalog_item_set
    INTERSECT
    SELECT inv_item_sk AS item_sk FROM inventory_subset
  ),
  final_union AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS metric,
           'catalog' AS source
    FROM catalog_subset cs
    JOIN common_items ci ON cs.cs_item_sk = ci.item_sk
    WHERE cs.cs_ext_sales_price > (SELECT max_price FROM max_price)
    UNION ALL
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_return_amt AS metric,
           'store' AS source
    FROM store_reason_subset sr
    WHERE sr.sr_return_amt > (SELECT max_price FROM max_price) * 0.2
  )
SELECT item_sk,
       metric,
       source
FROM final_union
ORDER BY metric DESC
LIMIT 100
