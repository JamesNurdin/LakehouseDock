/*
Goal: Identify high‑level performance metrics for items managed by manager 27 in the 'shirts' class, combining inventory levels, sales, and returns information. The query pre‑aggregates inventory, filters on realistic predicates, intersects item keys that have both sizable sales and returns, and provides aggregated results using GROUPING SETS with a row number for ordering.
*/
WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        AVG(inv_quantity_on_hand) AS avg_qty
    FROM tpcds.inventory
    WHERE inv_warehouse_sk = 5
      AND inv_quantity_on_hand > 500
    GROUP BY inv_item_sk
),
item_filtered AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_manager_id,
        i_class,
        i_brand,
        i_category
    FROM tpcds.item
    WHERE i_manager_id = 27
      AND i_class = 'shirts'
),
sales_agg AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_ext_wholesale_cost) AS sum_wholesale,
        SUM(ss_ext_sales_price) AS sum_sales,
        COUNT(*) AS cnt_sales
    FROM tpcds.store_sales
    WHERE ss_sales_price > 0
    GROUP BY ss_item_sk, ss_ticket_number
),
returns_agg AS (
    SELECT
        sr_item_sk,
        sr_ticket_number,
        SUM(sr_refunded_cash) AS sum_refunded,
        SUM(sr_return_ship_cost) AS sum_ship_cost,
        COUNT(*) AS cnt_returns
    FROM tpcds.store_returns
    WHERE sr_refunded_cash > 100
    GROUP BY sr_item_sk, sr_ticket_number
),
common_items AS (
    SELECT sr_item_sk AS item_sk
    FROM tpcds.store_returns
    WHERE sr_refunded_cash > 150
    INTERSECT
    SELECT ss_item_sk AS item_sk
    FROM tpcds.store_sales
    WHERE ss_sales_price > 20
)
SELECT
    ROW_NUMBER() OVER (ORDER BY item_filtered.i_brand, item_filtered.i_category) AS row_num,
    item_filtered.i_brand,
    item_filtered.i_category,
    SUM(inv_agg.total_qty)               AS total_inventory_qty,
    AVG(inv_agg.avg_qty)                 AS avg_inventory_qty,
    SUM(sales_agg.sum_wholesale)         AS total_wholesale,
    SUM(sales_agg.sum_sales)             AS total_sales,
    SUM(returns_agg.sum_refunded)        AS total_refunded,
    COUNT(DISTINCT item_filtered.i_item_sk) AS distinct_items
FROM inv_agg
JOIN item_filtered
  ON inv_agg.inv_item_sk = item_filtered.i_item_sk
JOIN sales_agg
  ON sales_agg.ss_item_sk = item_filtered.i_item_sk
JOIN returns_agg
  ON returns_agg.sr_item_sk = item_filtered.i_item_sk
JOIN common_items ci
  ON ci.item_sk = item_filtered.i_item_sk
GROUP BY GROUPING SETS (
    (item_filtered.i_brand, item_filtered.i_category),
    (item_filtered.i_brand),
    ()
)
ORDER BY row_num
LIMIT 100
