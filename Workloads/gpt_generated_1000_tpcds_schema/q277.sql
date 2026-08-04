/*
  Goal: Compare inventory and promotion performance across warehouses and brands under two different filter scenarios,
  aggregating total quantity on hand, average item price, and promotion count, then deduplicate the results via UNION,
  assign a global row number, and return the top 100 rows ordered by total quantity.
*/
WITH first_part AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        i.i_brand AS brand,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(i.i_current_price) AS avg_price,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
        MIN(i.i_rec_start_date) AS min_start_date,
        MAX(i.i_rec_end_date) AS max_end_date
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk = 10                -- specific warehouse
      AND i.i_size = 'medium'                     -- specific item size
      AND p.p_channel_radio = 'N'                 -- radio channel not used
    GROUP BY w.w_warehouse_name, i.i_brand
),
second_part AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        i.i_brand AS brand,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(i.i_current_price) AS avg_price,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
        MIN(i.i_rec_start_date) AS min_start_date,
        MAX(i.i_rec_end_date) AS max_end_date
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk = 20                -- another warehouse
      AND i.i_manager_id = 13                     -- manager filter
      AND p.p_channel_email = 'Y'                 -- email channel active
    GROUP BY w.w_warehouse_name, i.i_brand
)
SELECT
    row_number() OVER (ORDER BY total_qty DESC) AS row_num,
    warehouse_name,
    brand,
    total_qty,
    avg_price,
    promo_cnt,
    min_start_date,
    max_end_date
FROM (
    SELECT warehouse_name, brand, total_qty, avg_price, promo_cnt, min_start_date, max_end_date FROM first_part
    UNION
    SELECT warehouse_name, brand, total_qty, avg_price, promo_cnt, min_start_date, max_end_date FROM second_part
) u
ORDER BY total_qty DESC
OFFSET 0
LIMIT 100
