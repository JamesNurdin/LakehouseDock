WITH base_data AS (
    SELECT
        i.i_item_id,
        i.i_category,
        w.w_warehouse_id,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 50
      AND i.i_current_price < 200
      AND wp.wp_max_ad_count > 0
      AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_id, i.i_category, w.w_warehouse_id
)
SELECT
    bd.i_item_id,
    bd.i_category,
    bd.w_warehouse_id,
    bd.total_catalog_sales,
    bd.total_web_sales,
    bd.total_returns,
    bd.total_inventory,
    bd.catalog_orders,
    bd.web_orders,
    bd.total_web_sales / NULLIF(bd.total_catalog_sales, 0) AS web_to_catalog_sales_ratio,
    CASE WHEN bd.total_inventory > (SELECT AVG(total_inventory) FROM base_data) THEN 1 ELSE 0 END AS above_avg_inventory
FROM base_data bd
WHERE bd.total_returns > (SELECT AVG(total_returns) FROM base_data)
ORDER BY bd.total_inventory DESC
LIMIT 100
