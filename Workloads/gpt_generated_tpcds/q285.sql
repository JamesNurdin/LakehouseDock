/*
   Monthly net profit from catalog and web sales by item category and warehouse,
   together with the total quantity on hand from inventory for the same period.
   The query aggregates data for the year 2022.
*/
WITH sales_agg AS (
    -- Catalog sales contribution
    SELECT
        year(d.d_date) AS sales_year,
        month(d.d_date) AS sales_month,
        i.i_category AS category,
        w.w_warehouse_name AS warehouse_name,
        sum(cs.cs_net_profit) AS catalog_net_profit,
        CAST(0 AS decimal(7,2)) AS web_net_profit,
        CAST(0 AS integer) AS quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY year(d.d_date), month(d.d_date), i.i_category, w.w_warehouse_name

    UNION ALL

    -- Web sales contribution
    SELECT
        year(d.d_date) AS sales_year,
        month(d.d_date) AS sales_month,
        i.i_category AS category,
        w.w_warehouse_name AS warehouse_name,
        CAST(0 AS decimal(7,2)) AS catalog_net_profit,
        sum(ws.ws_net_profit) AS web_net_profit,
        CAST(0 AS integer) AS quantity_on_hand
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY year(d.d_date), month(d.d_date), i.i_category, w.w_warehouse_name

    UNION ALL

    -- Inventory snapshot contribution
    SELECT
        year(d.d_date) AS sales_year,
        month(d.d_date) AS sales_month,
        i.i_category AS category,
        w.w_warehouse_name AS warehouse_name,
        CAST(0 AS decimal(7,2)) AS catalog_net_profit,
        CAST(0 AS decimal(7,2)) AS web_net_profit,
        sum(inv.inv_quantity_on_hand) AS quantity_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY year(d.d_date), month(d.d_date), i.i_category, w.w_warehouse_name
)
SELECT
    sales_year,
    sales_month,
    category,
    warehouse_name,
    sum(catalog_net_profit) AS total_catalog_net_profit,
    sum(web_net_profit) AS total_web_net_profit,
    sum(quantity_on_hand) AS total_quantity_on_hand
FROM sales_agg
GROUP BY sales_year, sales_month, category, warehouse_name
ORDER BY sales_year, sales_month, category, warehouse_name
