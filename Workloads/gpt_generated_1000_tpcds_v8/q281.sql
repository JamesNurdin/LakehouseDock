WITH
    eligible_items AS (
        SELECT i_item_sk
        FROM item
        WHERE i_units = 'Carton'
          AND i_category_id IN (5, 10)
          AND i_manager_id = 64
        EXCEPT
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand = 0
    ),
    inv_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        WHERE inv_warehouse_sk IN (10, 6, 20)
          AND inv_quantity_on_hand > 0
        GROUP BY inv_item_sk
    ),
    returns_agg AS (
        SELECT cr_item_sk,
               SUM(cr_return_amount) AS total_return_amount,
               COUNT(*) AS return_cnt
        FROM catalog_returns
        WHERE cr_return_quantity > 0
          AND cr_return_amount > 0
          AND cr_returned_date_sk BETWEEN 20000101 AND 20231231
        GROUP BY cr_item_sk
    ),
    joined AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_current_price,
            i.i_units,
            i.i_category_id,
            i.i_manager_id,
            cp.cp_department,
            cp.cp_type,
            hd.hd_demo_sk,
            hd.hd_buy_potential,
            hd.hd_dep_count,
            inv_agg.total_on_hand,
            returns_agg.total_return_amount,
            returns_agg.return_cnt
        FROM item i
        INNER JOIN eligible_items ei ON i.i_item_sk = ei.i_item_sk
        LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
        LEFT JOIN returns_agg ON i.i_item_sk = returns_agg.cr_item_sk
        LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
        LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    )
SELECT
    cp_department,
    i_manager_id,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    SUM(total_on_hand) AS sum_on_hand,
    AVG(total_return_amount) AS avg_return_amount,
    SUM(i_current_price * total_on_hand) AS inventory_value,
    (SELECT AVG(i_current_price) FROM item WHERE i_units = 'Pallet') AS overall_avg_price_carton_units,
    ROW_NUMBER() OVER (ORDER BY SUM(total_on_hand) DESC) AS row_num
FROM joined
WHERE i_current_price BETWEEN 10 AND 1000
  AND hd_buy_potential = '5001-10000'
  AND hd_dep_count >= 2
  AND cp_type = 'PROMO'
  AND i_units <> 'Unknown'
  AND i_category_id <> 9
GROUP BY cp_department, i_manager_id
HAVING SUM(total_on_hand) > 0
ORDER BY sum_on_hand DESC, row_num
LIMIT 100
