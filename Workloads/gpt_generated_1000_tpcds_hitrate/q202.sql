WITH
    agg_inventory AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    sales_without_returns AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    )
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    MIN(cs.cs_sales_price) AS min_price,
    MAX(cs.cs_sales_price) AS max_price,
    (
        SELECT SUM(i3.inv_quantity_on_hand)
        FROM inventory i3
        WHERE i3.inv_item_sk = cs.cs_item_sk
          AND i3.inv_warehouse_sk = cs.cs_warehouse_sk
    ) AS current_inventory,
    SUM(agg_inventory.total_on_hand) AS agg_inventory_on_hand
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_item_sk = cr.cr_item_sk
   AND cs.cs_order_number = cr.cr_order_number
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN agg_inventory
    ON cs.cs_item_sk = agg_inventory.inv_item_sk
   AND cs.cs_warehouse_sk = agg_inventory.inv_warehouse_sk
JOIN sales_without_returns swr
    ON cs.cs_order_number = swr.cs_order_number
WHERE d_sold.d_year = 2001
  AND d_sold.d_month_seq BETWEEN 1200 AND 1210
  AND d_sold.d_dom IN (5, 7, 21)
  AND cr.cr_ship_mode_sk = 6
  AND agg_inventory.inv_warehouse_sk = 10
GROUP BY GROUPING SETS (
    (d_sold.d_year, d_sold.d_month_seq, cs.cs_item_sk, cs.cs_warehouse_sk),
    (d_sold.d_year, cs.cs_item_sk, cs.cs_warehouse_sk),
    (cs.cs_item_sk, cs.cs_warehouse_sk)
)
ORDER BY d_sold.d_year DESC, total_sales DESC
LIMIT 100
