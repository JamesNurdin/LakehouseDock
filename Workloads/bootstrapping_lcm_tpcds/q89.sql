WITH sold_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        COALESCE(cs_agg.total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(ws_agg.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs_agg.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(ws_agg.web_net_profit, 0) AS web_net_profit,
        COALESCE(cs_agg.catalog_quantity, 0) AS catalog_quantity,
        COALESCE(ws_agg.web_quantity, 0) AS web_quantity,
        COALESCE(cs_agg.distinct_catalog_items, 0) AS distinct_catalog_items,
        COALESCE(ws_agg.distinct_web_items, 0) AS distinct_web_items,
        COALESCE(inv_agg.avg_inventory_on_date, 0) AS avg_inventory_on_date,
        COALESCE(st_agg.stores_closed_count, 0) AS stores_closed_count
    FROM date_dim d
    LEFT JOIN (
        SELECT
            cs_sold_date_sk,
            SUM(cs_ext_sales_price) AS total_catalog_sales,
            SUM(cs_net_profit) AS catalog_net_profit,
            SUM(cs_quantity) AS catalog_quantity,
            COUNT(DISTINCT cs_item_sk) AS distinct_catalog_items
        FROM catalog_sales
        GROUP BY cs_sold_date_sk
    ) cs_agg
        ON cs_agg.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN (
        SELECT
            ws_sold_date_sk,
            SUM(ws_ext_sales_price) AS total_web_sales,
            SUM(ws_net_profit) AS web_net_profit,
            SUM(ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws_item_sk) AS distinct_web_items
        FROM web_sales
        GROUP BY ws_sold_date_sk
    ) ws_agg
        ON ws_agg.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN (
        SELECT
            inv_date_sk,
            AVG(inv_quantity_on_hand) AS avg_inventory_on_date
        FROM inventory
        GROUP BY inv_date_sk
    ) inv_agg
        ON inv_agg.inv_date_sk = d.d_date_sk
    LEFT JOIN (
        SELECT
            s_closed_date_sk,
            COUNT(DISTINCT s_store_id) AS stores_closed_count
        FROM store
        GROUP BY s_closed_date_sk
    ) st_agg
        ON st_agg.s_closed_date_sk = d.d_date_sk
),
ship_agg AS (
    SELECT
        d.d_date AS ship_date,
        COALESCE(cs_ship_agg.total_catalog_ship_cost, 0) AS total_catalog_ship_cost,
        COALESCE(cs_ship_agg.total_catalog_ship_tax, 0) AS total_catalog_ship_tax,
        COALESCE(ws_ship_agg.total_web_ship_cost, 0) AS total_web_ship_cost,
        COALESCE(ws_ship_agg.total_web_ship_tax, 0) AS total_web_ship_tax
    FROM date_dim d
    LEFT JOIN (
        SELECT
            cs_ship_date_sk,
            SUM(cs_ext_ship_cost) AS total_catalog_ship_cost,
            SUM(cs_ext_tax) AS total_catalog_ship_tax
        FROM catalog_sales
        GROUP BY cs_ship_date_sk
    ) cs_ship_agg
        ON cs_ship_agg.cs_ship_date_sk = d.d_date_sk
    LEFT JOIN (
        SELECT
            ws_ship_date_sk,
            SUM(ws_ext_ship_cost) AS total_web_ship_cost,
            SUM(ws_ext_tax) AS total_web_ship_tax
        FROM web_sales
        GROUP BY ws_ship_date_sk
    ) ws_ship_agg
        ON ws_ship_agg.ws_ship_date_sk = d.d_date_sk
)
SELECT
    sm.d_date,
    sm.d_year,
    sm.d_month_seq,
    sm.total_catalog_sales,
    sm.total_web_sales,
    sm.catalog_net_profit,
    sm.web_net_profit,
    (sm.total_catalog_sales + sm.total_web_sales) AS total_combined_sales,
    (sm.catalog_quantity + sm.web_quantity) AS total_quantity,
    sm.avg_inventory_on_date,
    sm.stores_closed_count,
    sm.distinct_catalog_items,
    sm.distinct_web_items,
    COALESCE(sh.total_catalog_ship_cost, 0) AS total_catalog_ship_cost,
    COALESCE(sh.total_web_ship_cost, 0) AS total_web_ship_cost,
    COALESCE(sh.total_catalog_ship_tax, 0) AS total_catalog_ship_tax,
    COALESCE(sh.total_web_ship_tax, 0) AS total_web_ship_tax,
    RANK() OVER (ORDER BY (sm.total_catalog_sales + sm.total_web_sales) DESC) AS sales_rank
FROM sold_agg sm
LEFT JOIN ship_agg sh
    ON sm.d_date = sh.ship_date
WHERE (sm.total_catalog_sales + sm.total_web_sales) > 0
ORDER BY sales_rank
LIMIT 50
