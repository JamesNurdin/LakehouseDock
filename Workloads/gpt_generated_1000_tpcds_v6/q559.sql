WITH
  cr_base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_fee
    FROM catalog_returns cr
  ),
  d_ret AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_holiday = 'N'
  ),
  d_inv AS (
    SELECT *
    FROM date_dim
  ),
  d_ret2 AS (
    SELECT *
    FROM date_dim
  ),
  wp_creation AS (
    SELECT *
    FROM web_page
  ),
  wp_access AS (
    SELECT *
    FROM web_page
  ),
  inv AS (
    SELECT *
    FROM inventory
  ),
  inv2 AS (
    SELECT *
    FROM inventory
  ),
  it AS (
    SELECT *
    FROM item
  )
SELECT
  d_ret.d_year,
  it.i_brand,
  wp_creation.wp_type,
  SUM(cr_base.cr_return_amount)               AS total_return_amount,
  SUM(cr_base.cr_return_quantity)             AS total_return_quantity,
  AVG(inv.inv_quantity_on_hand)               AS avg_inventory_qty,
  AVG(inv2.inv_quantity_on_hand)              AS avg_inventory_qty_2,
  COUNT(DISTINCT it.i_item_sk)                AS distinct_items,
  COUNT(DISTINCT wp_creation.wp_web_page_id)  AS distinct_pages_created,
  COUNT(DISTINCT wp_access.wp_web_page_id)    AS distinct_pages_accessed
FROM cr_base
JOIN d_ret
  ON cr_base.cr_returned_date_sk = d_ret.d_date_sk                                     -- join 1
JOIN it
  ON cr_base.cr_item_sk = it.i_item_sk                                                   -- join 2
JOIN inv
  ON inv.inv_item_sk = it.i_item_sk                                                       -- join 3
JOIN d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk                                                   -- join 4
JOIN wp_creation
  ON wp_creation.wp_creation_date_sk = d_ret.d_date_sk                                 -- join 5
JOIN wp_access
  ON wp_access.wp_access_date_sk = d_inv.d_date_sk                                      -- join 6
JOIN inv2
  ON inv2.inv_item_sk = it.i_item_sk                                                      -- join 7
JOIN d_ret2
  ON inv2.inv_date_sk = d_ret2.d_date_sk                                                 -- join 8
JOIN wp_creation wp3
  ON wp3.wp_creation_date_sk = d_ret2.d_date_sk                                         -- join 9
GROUP BY d_ret.d_year, it.i_brand, wp_creation.wp_type
ORDER BY total_return_amount DESC
LIMIT 100
