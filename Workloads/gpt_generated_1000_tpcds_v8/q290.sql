WITH filtered_items AS (
  SELECT i_item_sk
  FROM item
  WHERE i_category = 'Sports'
  INTERSECT
  SELECT inv_item_sk
  FROM inventory
  WHERE inv_warehouse_sk = 5
),
base AS (
  SELECT
    cr.cr_item_sk,
    i.i_category,
    dem_ret.cd_gender AS returning_gender,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    i.i_current_price,
    wp.wp_char_count
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk                     -- 1
  JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk   -- 2
  JOIN customer_demographics dem_ref ON cr.cr_refunded_cdemo_sk = dem_ref.cd_demo_sk   -- 3
  JOIN customer cust_ret ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk   -- 4
  JOIN customer_demographics dem_ret ON cr.cr_returning_cdemo_sk = dem_ret.cd_demo_sk   -- 5
  LEFT JOIN web_page wp ON wp.wp_customer_sk = cust_ret.c_customer_sk               -- 6 (semi‑join later)
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk                               -- 7
  JOIN customer_demographics dem_curr ON cust_ref.c_current_cdemo_sk = dem_curr.cd_demo_sk   -- 8
  JOIN inventory inv_wh ON inv_wh.inv_item_sk = i.i_item_sk AND inv_wh.inv_warehouse_sk = 5   -- 9
  WHERE
    cr.cr_item_sk IN (SELECT i_item_sk FROM filtered_items)
    AND EXISTS (SELECT 1 FROM inventory inv2 WHERE inv2.inv_item_sk = i.i_item_sk AND inv2.inv_quantity_on_hand > 0)
    AND (wp.wp_char_count IS NULL OR wp.wp_char_count > 1500)
)
SELECT
  b.i_category,
  b.returning_gender,
  COUNT(DISTINCT b.cr_item_sk)                AS distinct_items_returned,
  SUM(b.cr_return_quantity)                  AS total_return_quantity,
  SUM(b.cr_return_amount)                    AS total_return_amount,
  AVG(b.cr_return_amount)                    AS avg_return_amount,
  AVG(b.i_current_price)                     AS avg_item_price,
  (SELECT SUM(cr3.cr_return_amount)
     FROM catalog_returns cr3
    WHERE cr3.cr_item_sk = b.cr_item_sk)   AS total_item_return_amount,
  ROW_NUMBER() OVER (ORDER BY SUM(b.cr_return_amount) DESC) AS rn
FROM base b
GROUP BY
  b.i_category,
  b.returning_gender,
  b.cr_item_sk,
  b.i_current_price
ORDER BY total_return_amount DESC
LIMIT 100
