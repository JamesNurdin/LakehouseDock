WITH filtered_items AS (
    SELECT i_item_sk, i_brand
    FROM item
    WHERE i_rec_start_date >= DATE '2000-01-01'
),
filtered_warehouses AS (
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_county = 'Fairfield County'
)
SELECT brand, sales_channel, total_net_paid
FROM (
    SELECT fi.i_brand AS brand,
           'catalog' AS sales_channel,
           SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    JOIN filtered_warehouses fw ON cs.cs_warehouse_sk = fw.w_warehouse_sk
    GROUP BY fi.i_brand

    UNION ALL

    SELECT fi.i_brand AS brand,
           'web' AS sales_channel,
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    JOIN filtered_warehouses fw ON ws.ws_warehouse_sk = fw.w_warehouse_sk
    GROUP BY fi.i_brand
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
