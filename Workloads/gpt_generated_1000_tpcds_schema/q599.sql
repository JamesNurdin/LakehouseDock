WITH
    sampled_inventory AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    catalog_data AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_fee,
            cr.cr_net_loss,
            cr.cr_warehouse_sk,
            w.w_warehouse_name,
            w.w_state,
            r.r_reason_desc,
            c.c_customer_id,
            cd.cd_gender
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    ),
    web_data AS (
        SELECT
            ws.ws_order_number,
            ws.ws_net_paid,
            ws.ws_ext_tax,
            ws.ws_warehouse_sk,
            w.w_warehouse_name,
            w.w_state,
            r.r_reason_desc,
            wc.web_site_id,
            c.c_customer_id,
            cd.cd_gender
        FROM web_sales ws
        JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_site wc ON ws.ws_web_site_sk = wc.web_site_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    ),
    common_orders AS (
        SELECT cr_order_number AS order_number FROM catalog_returns
        INTERSECT
        SELECT ws_order_number FROM web_sales
    ),
    union_warehouses AS (
        SELECT inv_warehouse_sk FROM inventory
        UNION
        SELECT inv_warehouse_sk FROM sampled_inventory
    ),
    warehouse_inventory AS (
        SELECT w.w_warehouse_sk,
               w.w_warehouse_name,
               li.total_qty
        FROM warehouse w
        LEFT JOIN LATERAL (
            SELECT SUM(si.inv_quantity_on_hand) AS total_qty
            FROM sampled_inventory si
            WHERE si.inv_warehouse_sk = w.w_warehouse_sk
        ) li ON TRUE
    )
SELECT
    COALESCE(cd.cr_warehouse_sk, wd.ws_warehouse_sk) AS warehouse_sk,
    COALESCE(cd.w_warehouse_name, wd.w_warehouse_name) AS warehouse_name,
    COALESCE(cd.w_state, wd.w_state) AS state,
    COALESCE(cd.r_reason_desc, wd.r_reason_desc) AS reason_desc,
    SUM(COALESCE(cd.cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(wd.ws_net_paid, 0)) AS total_net_paid,
    COUNT(DISTINCT COALESCE(cd.cr_order_number, wd.ws_order_number)) AS distinct_orders,
    MAX(warehouse_inv.total_qty) AS max_sampled_inventory_qty
FROM catalog_data cd
FULL OUTER JOIN web_data wd
    ON cd.cr_warehouse_sk = wd.ws_warehouse_sk
JOIN union_warehouses uw
    ON uw.inv_warehouse_sk = COALESCE(cd.cr_warehouse_sk, wd.ws_warehouse_sk)
LEFT JOIN warehouse_inventory warehouse_inv
    ON warehouse_inv.w_warehouse_sk = COALESCE(cd.cr_warehouse_sk, wd.ws_warehouse_sk)
WHERE COALESCE(cd.w_state, wd.w_state) = 'WV'
  AND COALESCE(cd.r_reason_desc, wd.r_reason_desc) LIKE '%damaged%'
  AND (COALESCE(cd.cr_net_loss, 0) > 0 OR COALESCE(wd.ws_net_paid, 0) > 100)
  AND EXISTS (
        SELECT 1 FROM common_orders co
        WHERE co.order_number = COALESCE(cd.cr_order_number, wd.ws_order_number)
    )
GROUP BY
    COALESCE(cd.cr_warehouse_sk, wd.ws_warehouse_sk),
    COALESCE(cd.w_warehouse_name, wd.w_warehouse_name),
    COALESCE(cd.w_state, wd.w_state),
    COALESCE(cd.r_reason_desc, wd.r_reason_desc)
ORDER BY total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
