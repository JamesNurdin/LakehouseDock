WITH
    filtered_inventory AS (
        SELECT inv.inv_date_sk,
               inv.inv_item_sk,
               inv.inv_quantity_on_hand
        FROM tpcds.inventory inv
        WHERE inv.inv_date_sk BETWEEN 2450800 AND 2450900
          AND inv.inv_quantity_on_hand > 100
    ),
    item_promo AS (
        SELECT i.i_item_sk,
               i.i_product_name,
               i.i_manager_id,
               i.i_category,
               p.p_discount_active,
               p.p_channel_press
        FROM tpcds.item i
        JOIN tpcds.promotion p
              ON p.p_item_sk = i.i_item_sk
        WHERE p.p_discount_active = 'Y'
          AND p.p_channel_press = 'N'
    ),
    aggregated AS (
        SELECT fi.inv_date_sk,
               ip.i_item_sk,
               ip.i_product_name,
               ip.i_manager_id,
               ip.i_category,
               ip.p_discount_active,
               SUM(fi.inv_quantity_on_hand) AS total_quantity
        FROM filtered_inventory fi
        JOIN tpcds.item i
          ON fi.inv_item_sk = i.i_item_sk
        JOIN item_promo ip
          ON i.i_item_sk = ip.i_item_sk
        WHERE i.i_manager_id IN (25, 44)
        GROUP BY fi.inv_date_sk,
                 ip.i_item_sk,
                 ip.i_product_name,
                 ip.i_manager_id,
                 ip.i_category,
                 ip.p_discount_active
    )
SELECT a.inv_date_sk,
       a.i_item_sk,
       a.i_product_name,
       a.total_quantity,
       RANK() OVER (ORDER BY a.total_quantity DESC) AS quantity_rank,
       CASE WHEN a.p_discount_active = 'Y' THEN 'Discount' ELSE 'No Discount' END AS discount_flag,
       (SELECT AVG(sub.total_quantity)
        FROM (
            SELECT SUM(fi2.inv_quantity_on_hand) AS total_quantity
            FROM tpcds.inventory fi2
            WHERE fi2.inv_date_sk BETWEEN 2450800 AND 2450900
            GROUP BY fi2.inv_item_sk
        ) sub) AS overall_avg_quantity
FROM aggregated a
ORDER BY quantity_rank
LIMIT 20
