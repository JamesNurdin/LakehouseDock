WITH
-- Sample a fraction of catalog_sales to limit the data scanned
sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 5
      AND cs_wholesale_cost < 100
),

-- Full outer join between inventory and warehouse (keeps unmatched rows on both sides)
full_inventory AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        wh.w_warehouse_sk,
        wh.w_warehouse_name,
        wh.w_city,
        wh.w_zip,
        wh.w_street_type
    FROM inventory inv
    FULL OUTER JOIN warehouse wh
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 500
       OR wh.w_city = 'Seattle'
),

-- Join the sampled sales with returns, demographics and warehouse using only the allowed keys
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cd.cd_gender,
        cd.cd_dep_employed_count,
        wh.w_warehouse_name,
        wh.w_city,
        wh.w_zip,
        wh.w_street_type
    FROM sampled_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    WHERE wh.w_street_type = 'Avenue'
      AND wh.w_zip = '56098'
      AND cd.cd_dep_employed_count <= 2
      -- ensure the warehouse appears in the full outer join result (subquery example)
      AND EXISTS (
          SELECT 1
          FROM full_inventory fi
          WHERE fi.w_warehouse_sk = cs.cs_warehouse_sk
      )
),

-- Aggregate the joined data
aggregated AS (
    SELECT
        w_warehouse_name,
        w_city,
        cd_gender,
        cs_warehouse_sk,
        SUM(cs_net_paid)                         AS total_sales,
        AVG(cs_net_paid)                         AS avg_sales,
        COUNT(DISTINCT cs_item_sk)               AS distinct_items_sold,
        SUM(DISTINCT cr_return_amount)           AS distinct_return_amount,
        MIN(cr_return_quantity)                  AS min_return_qty,
        MAX(cs_quantity)                         AS max_quantity_sold
    FROM joined_data
    GROUP BY w_warehouse_name, w_city, cd_gender, cs_warehouse_sk
)

SELECT
    ROW_NUMBER() OVER (ORDER BY total_sales DESC)                AS row_num,
    w_warehouse_name,
    w_city,
    cd_gender,
    total_sales,
    avg_sales,
    distinct_items_sold,
    distinct_return_amount,
    min_return_qty,
    max_quantity_sold,
    -- scalar subquery returning total inventory for the warehouse
    (SELECT SUM(inv_quantity_on_hand)
     FROM inventory inv
     WHERE inv.inv_warehouse_sk = a.cs_warehouse_sk)          AS total_inventory_for_warehouse,
    -- analytic window function (lag of total sales within each warehouse)
    LAG(total_sales) OVER (PARTITION BY w_warehouse_name ORDER BY w_city) AS lag_total_sales
FROM aggregated a
ORDER BY total_sales DESC
LIMIT 100
