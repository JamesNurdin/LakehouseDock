WITH
  store_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(ss.ss_ext_sales_price) AS sales_amount,
      'store' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
  ),
  catalog_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(cs.cs_ext_sales_price) AS sales_amount,
      'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
  ),
  union_sales AS (
    SELECT i_item_sk, i_item_id, sales_amount, channel FROM store_sales_agg
    UNION
    SELECT i_item_sk, i_item_id, sales_amount, channel FROM catalog_sales_agg
  ),
  returns_items AS (
    SELECT DISTINCT sr_item_sk FROM store_returns
  ),
  items_no_return AS (
    SELECT i_item_sk FROM union_sales
    EXCEPT
    SELECT sr_item_sk FROM returns_items
  ),
  inventory_all AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
    FROM item i
    FULL OUTER JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  )
SELECT
  us.i_item_id,
  us.sales_amount,
  us.channel,
  inv.quantity_on_hand,
  (
    SELECT COALESCE(SUM(sr.sr_return_amt_inc_tax), 0)
    FROM store_returns sr
    WHERE sr.sr_item_sk = us.i_item_sk
  ) AS total_return_amount,
  (
    SELECT AVG(s.s_tax_percentage)
    FROM store s
  ) AS avg_store_tax,
  CASE
    WHEN us.sales_amount > (
      SELECT MAX(sales_amount) FROM union_sales
    ) THEN TRUE
    ELSE FALSE
  END AS is_top_sales
FROM union_sales us
JOIN items_no_return ir ON us.i_item_sk = ir.i_item_sk
FULL OUTER JOIN inventory_all inv ON us.i_item_sk = inv.i_item_sk
WHERE us.sales_amount > (
  SELECT MIN(sales_amount) FROM union_sales
)
ORDER BY us.sales_amount DESC
LIMIT 100
