/*
 * Goal: Identify the top stocked items per California warehouse for the current year and month, 
 * comparing the current item price with the latest active price, ranking items by quantity on hand,
 * and flagging stock status. The query joins the fact table inventory with date_dim, item, and warehouse
 * (star schema), applies four filter predicates, uses a CROSS JOIN LATERAL to fetch the latest price,
 * and employs window functions for ranking.
 */
WITH filtered_inventory AS (
    SELECT 
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        i.i_wholesale_cost,
        i.i_current_price,
        w.w_warehouse_name,
        w.w_city
    FROM tpcds.inventory AS inv
    JOIN tpcds.date_dim AS d
      ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.item AS i
      ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.warehouse AS w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_current_year = 'Y'                     -- predicate 1
      AND d.d_current_month = 'Y'                    -- predicate 2
      AND i.i_wholesale_cost > 5.00                  -- predicate 3
      AND w.w_state = 'CA'                           -- predicate 4
)
SELECT 
    f.inv_date_sk,
    f.inv_item_sk,
    f.inv_warehouse_sk,
    f.inv_quantity_on_hand,
    f.d_date,
    f.d_year,
    f.d_month_seq,
    f.i_item_id,
    f.i_product_name,
    f.i_wholesale_cost,
    f.i_current_price,
    f.w_warehouse_name,
    f.w_city,
    lp.latest_price,
    (lp.latest_price - f.i_current_price) AS price_diff,
    ROW_NUMBER() OVER (PARTITION BY f.w_warehouse_name ORDER BY f.inv_quantity_on_hand DESC) AS rn_warehouse,
    RANK() OVER (ORDER BY f.inv_quantity_on_hand DESC) AS global_qty_rank,
    CASE WHEN f.inv_quantity_on_hand = 0 THEN 'Out of Stock' ELSE 'In Stock' END AS stock_status
FROM filtered_inventory AS f
CROSS JOIN LATERAL (
    SELECT i2.i_current_price AS latest_price
    FROM tpcds.item AS i2
    WHERE i2.i_item_sk = f.inv_item_sk
      AND i2.i_rec_start_date <= CURRENT_DATE
      AND i2.i_rec_end_date > CURRENT_DATE
    ORDER BY i2.i_rec_end_date DESC
    LIMIT 1
) AS lp
ORDER BY f.inv_quantity_on_hand DESC
LIMIT 100
