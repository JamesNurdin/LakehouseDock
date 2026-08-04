WITH
  promo_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           d.d_year
    FROM tpcds.item i
    JOIN tpcds.promotion p ON i.i_item_sk = p.p_item_sk
    JOIN tpcds.date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
  ),
  return_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           sr.sr_return_amt,
           d.d_year
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND sr.sr_return_amt > 100
  ),
  intersect_items AS (
    SELECT pi.i_item_sk,
           pi.i_product_name
    FROM promo_items pi
    INTERSECT
    SELECT ri.i_item_sk,
           ri.i_product_name
    FROM return_items ri
  ),
  no_inventory_items AS (
    SELECT i.i_item_sk
    FROM tpcds.item i
    WHERE NOT EXISTS (
      SELECT 1
      FROM tpcds.inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_quantity_on_hand > 0
    )
  ),
  excluded_items AS (
    SELECT ri.i_item_sk
    FROM return_items ri
    EXCEPT
    SELECT pi.i_item_sk
    FROM promo_items pi
  ),
  final_items AS (
    SELECT ii.i_item_sk,
           ii.i_product_name,
           CASE WHEN ri.sr_return_amt > 500 THEN 'HIGH' ELSE 'NORMAL' END AS return_category,
           (SELECT avg(sr2.sr_return_amt)
            FROM tpcds.store_returns sr2
            WHERE sr2.sr_item_sk = ii.i_item_sk) AS avg_return_amt
    FROM intersect_items ii
    JOIN return_items ri ON ii.i_item_sk = ri.i_item_sk
    WHERE NOT EXISTS (
      SELECT 1
      FROM no_inventory_items ni
      WHERE ni.i_item_sk = ii.i_item_sk
    )
  ),
  inventory_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           'INVENTORY_ONLY' AS return_category,
           NULL AS avg_return_amt
    FROM tpcds.inventory inv
    JOIN tpcds.item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND i.i_item_sk NOT IN (SELECT i_item_sk FROM final_items)
  )
SELECT i_item_sk,
       i_product_name,
       return_category,
       avg_return_amt
FROM final_items
UNION ALL
SELECT i_item_sk,
       i_product_name,
       return_category,
       avg_return_amt
FROM inventory_items
LIMIT 100
