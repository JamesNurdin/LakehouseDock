WITH sales_inventory AS (
    SELECT
        i.i_category,
        i.i_class,
        w.w_warehouse_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_category, i.i_class, w.w_warehouse_name, d.d_year
)
SELECT
    i_category,
    i_class,
    w_warehouse_name,
    d_year,
    total_sales,
    total_quantity,
    avg_sales_price,
    total_profit,
    avg_inventory_on_hand,
    total_sales - total_profit AS sales_excluding_profit,
    RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank_in_warehouse
FROM sales_inventory
ORDER BY total_sales DESC
LIMIT 10
