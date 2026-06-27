WITH cs AS (
    SELECT
        w.w_warehouse_id,
        td.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY w.w_warehouse_id, td.t_hour
),
ws AS (
    SELECT
        w.w_warehouse_id,
        td.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_paid) AS total_web_net_paid
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY w.w_warehouse_id, td.t_hour
),
cr AS (
    SELECT
        w.w_warehouse_id,
        td.t_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY w.w_warehouse_id, td.t_hour
),
inv AS (
    SELECT
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT
    cs.w_warehouse_id,
    cs.t_hour,
    cs.total_catalog_sales,
    cs.total_catalog_net_paid,
    ws.total_web_sales,
    ws.total_web_net_paid,
    cr.total_return_amount,
    cr.total_refunded_cash,
    inv.total_quantity_on_hand
FROM cs
LEFT JOIN ws ON cs.w_warehouse_id = ws.w_warehouse_id AND cs.t_hour = ws.t_hour
LEFT JOIN cr ON cs.w_warehouse_id = cr.w_warehouse_id AND cs.t_hour = cr.t_hour
LEFT JOIN inv ON cs.w_warehouse_id = inv.w_warehouse_id
ORDER BY cs.w_warehouse_id, cs.t_hour
