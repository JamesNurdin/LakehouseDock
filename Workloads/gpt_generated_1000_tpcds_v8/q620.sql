WITH
  -- Full outer join of returns and sales on both order and item keys
  joined_full AS (
    SELECT
      cr.cr_order_number,
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      CASE
        WHEN cr.cr_return_amount > cs.cs_ext_sales_price THEN 'HigherReturn'
        ELSE 'LowerReturn'
      END AS return_vs_sales_flag
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    WHERE (cr.cr_return_amount IS NOT NULL AND cr.cr_return_amount > 10)
       OR (cs.cs_ext_sales_price IS NOT NULL AND cs.cs_ext_sales_price > 10)
  ),

  -- Key set from returns with significant store credit
  set_a AS (
    SELECT cr_order_number, cr_item_sk
    FROM catalog_returns
    WHERE cr_store_credit > 20
  ),

  -- Key set from sales with very high shipping cost
  set_b AS (
    SELECT cs_order_number AS cr_order_number, cs_item_sk AS cr_item_sk
    FROM catalog_sales
    WHERE cs_ext_ship_cost > 500
  ),

  -- Returns keys that do NOT appear in the high‑shipping‑cost sales set
  except_set AS (
    SELECT cr_order_number, cr_item_sk FROM set_a
    EXCEPT
    SELECT cr_order_number, cr_item_sk FROM set_b
  ),

  -- Returns keys that also appear in the high‑shipping‑cost sales set
  intersect_set AS (
    SELECT cr_order_number, cr_item_sk FROM set_a
    INTERSECT
    SELECT cr_order_number, cr_item_sk FROM set_b
  ),

  -- Union of both key sets (deduplicated)
  union_set AS (
    SELECT cr_order_number, cr_item_sk FROM set_a
    UNION
    SELECT cr_order_number, cr_item_sk FROM set_b
  ),

  -- Final set combines rows from the joined view whose keys are in either EXCEPT or INTERSECT
  final AS (
    SELECT
      j.cr_order_number,
      j.cr_item_sk,
      j.return_vs_sales_flag,
      ROW_NUMBER() OVER (PARTITION BY j.cr_item_sk ORDER BY j.cr_return_amount DESC NULLS LAST) AS rn
    FROM joined_full j
    WHERE (j.cr_order_number, j.cr_item_sk) IN (
            SELECT cr_order_number, cr_item_sk FROM except_set
            UNION ALL
            SELECT cr_order_number, cr_item_sk FROM intersect_set
          )
  )
SELECT
  cr_order_number,
  cr_item_sk,
  return_vs_sales_flag,
  rn
FROM final
ORDER BY rn ASC, cr_order_number DESC
LIMIT 100
