WITH
    sales_agg AS (
        SELECT
            w.w_warehouse_id,
            w.w_warehouse_name,
            cp.cp_department,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_sales_profit
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_id, w.w_warehouse_name, cp.cp_department
    ),
    returns_agg AS (
        SELECT
            w.w_warehouse_id,
            w.w_warehouse_name,
            cp.cp_department,
            SUM(cr.cr_return_amount) AS total_returns,
            SUM(cr.cr_net_loss) AS total_returns_loss
        FROM catalog_returns cr
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_id, w.w_warehouse_name, cp.cp_department
    ),
    inventory_agg AS (
        SELECT
            w.w_warehouse_id,
            w.w_warehouse_name,
            SUM(inv.inv_quantity_on_hand) AS total_inventory
        FROM inventory inv
        JOIN warehouse w
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_id, w.w_warehouse_name
    ),
    web_sales_agg AS (
        SELECT
            w.w_warehouse_id,
            w.w_warehouse_name,
            SUM(ws.ws_net_profit) AS total_web_profit
        FROM web_sales ws
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_id, w.w_warehouse_name
    )
SELECT
    s.w_warehouse_id,
    s.w_warehouse_name,
    s.cp_department,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
    s.total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    s.total_sales_profit - COALESCE(r.total_returns_loss, 0) AS net_profit,
    COALESCE(i.total_inventory, 0) AS total_inventory,
    COALESCE(ws.total_web_profit, 0) AS total_web_profit
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.w_warehouse_id = r.w_warehouse_id
    AND s.cp_department = r.cp_department
LEFT JOIN inventory_agg i
    ON s.w_warehouse_id = i.w_warehouse_id
LEFT JOIN web_sales_agg ws
    ON s.w_warehouse_id = ws.w_warehouse_id
ORDER BY net_profit DESC
LIMIT 10
