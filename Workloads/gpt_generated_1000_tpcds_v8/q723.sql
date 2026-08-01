/*
Goal: Compare aggregated catalog and web sales by warehouse and item class, compute ranks, and illustrate various set operations, window functions, anti‑joins, cross joins, and rollup subtotals.
*/
WITH
    -- Raw aggregation of catalog sales with ROLLUP for subtotals
    agg_catalog_raw AS (
        SELECT
            w.w_warehouse_name AS w_name,
            i.i_class AS class,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910   -- example surrogate key range
        GROUP BY ROLLUP (w.w_warehouse_name, i.i_class)
    ),
    -- Add a window rank per warehouse based on total_sales
    agg_catalog AS (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY w_name ORDER BY total_sales DESC) AS warehouse_sales_rank
        FROM agg_catalog_raw
    ),
    -- Simple aggregation of web sales (no rollup needed here)
    agg_web AS (
        SELECT
            w.w_warehouse_name AS w_name,
            i.i_class AS class,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit
        FROM web_sales ws
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
        GROUP BY w.w_warehouse_name, i.i_class
    ),
    -- Anti‑join: items sold in catalog that have never been returned
    items_not_returned AS (
        SELECT DISTINCT cs.cs_item_sk
        FROM catalog_sales cs
        WHERE NOT EXISTS (
            SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = cs.cs_item_sk
        )
    ),
    -- Items that do have returns (used for EXCEPT later)
    returned_items AS (
        SELECT DISTINCT sr.sr_item_sk FROM store_returns sr
    ),
    -- EXCEPT: items sold in catalog but not present in store_returns
    items_sold_not_returned AS (
        SELECT cs.cs_item_sk FROM catalog_sales cs
        EXCEPT
        SELECT sr.sr_item_sk FROM store_returns sr
    ),
    -- Small dimension table for a CROSS JOIN (years 1999‑2001)
    years AS (
        SELECT year FROM (VALUES 1999, 2000, 2001) AS t(year)
    ),
    -- Cartesian product of years and distinct warehouses
    cross_join_example AS (
        SELECT y.year, w.w_warehouse_name
        FROM years y
        CROSS JOIN (SELECT DISTINCT w_warehouse_name FROM warehouse) w
    ),
    -- INTERSECT: item keys that appear in both catalog_sales and web_sales
    common_item_keys AS (
        SELECT cs.cs_item_sk FROM catalog_sales cs
        INTERSECT
        SELECT ws.ws_item_sk FROM web_sales ws
    ),
    -- Combine the two aggregated result sets with UNION ALL
    final_union AS (
        SELECT
            'Catalog' AS source,
            w_name,
            class,
            total_sales,
            total_profit,
            warehouse_sales_rank
        FROM agg_catalog
        UNION ALL
        SELECT
            'Web' AS source,
            w_name,
            class,
            total_sales,
            total_profit,
            NULL AS warehouse_sales_rank
        FROM agg_web
    )
SELECT
    source,
    w_name,
    class,
    total_sales,
    total_profit,
    warehouse_sales_rank
FROM final_union
ORDER BY source, w_name, class
LIMIT 100
