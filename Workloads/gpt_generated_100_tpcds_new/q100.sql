WITH
    agg_inventory AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
    ),
    order_diff AS (
        SELECT ws_order_number AS order_num
        FROM web_sales
        EXCEPT
        SELECT cr_order_number AS order_num
        FROM catalog_returns
    ),
    src AS (
        SELECT
            ws.ws_order_number                     AS order_num,
            ws.ws_sold_date_sk                     AS d_date_sk,
            ws.ws_item_sk                          AS i_item_sk,
            ws.ws_ship_mode_sk                     AS sm_ship_mode_sk,
            ws.ws_warehouse_sk                     AS w_warehouse_sk,
            ws.ws_bill_customer_sk                 AS c_customer_sk,
            ws.ws_bill_hdemo_sk                    AS hd_demo_sk,
            ws.ws_sold_time_sk                     AS t_time_sk,
            ws.ws_web_site_sk                      AS ws_web_site_sk,
            NULL                                   AS cc_call_center_sk,
            NULL                                   AS cp_catalog_page_sk,
            ws.ws_quantity                         AS qty,
            agg.total_qty
        FROM web_sales ws
        LEFT JOIN agg_inventory agg
            ON ws.ws_item_sk = agg.inv_item_sk
           AND ws.ws_warehouse_sk = agg.inv_warehouse_sk
           AND ws.ws_sold_date_sk = agg.inv_date_sk
        UNION
        SELECT
            cr.cr_order_number                     AS order_num,
            cr.cr_returned_date_sk                 AS d_date_sk,
            cr.cr_item_sk                          AS i_item_sk,
            cr.cr_ship_mode_sk                     AS sm_ship_mode_sk,
            cr.cr_warehouse_sk                     AS w_warehouse_sk,
            cr.cr_refunded_customer_sk             AS c_customer_sk,
            cr.cr_refunded_hdemo_sk                AS hd_demo_sk,
            cr.cr_returned_time_sk                 AS t_time_sk,
            NULL                                   AS ws_web_site_sk,
            cr.cr_call_center_sk                   AS cc_call_center_sk,
            cr.cr_catalog_page_sk                  AS cp_catalog_page_sk,
            cr.cr_return_quantity                  AS qty,
            agg2.total_qty
        FROM catalog_returns cr
        LEFT JOIN agg_inventory agg2
            ON cr.cr_item_sk = agg2.inv_item_sk
           AND cr.cr_warehouse_sk = agg2.inv_warehouse_sk
           AND cr.cr_returned_date_sk = agg2.inv_date_sk
    )
SELECT
    d.d_year,
    i.i_category,
    sm.sm_type,
    w.w_warehouse_name,
    SUM(src.qty)                                 AS total_quantity,
    SUM(COALESCE(src.total_qty, 0))              AS total_on_hand,
    COUNT(DISTINCT c.c_customer_id)              AS distinct_customers,
    COUNT(DISTINCT od.order_num)                 AS diff_orders
FROM src
JOIN date_dim d               ON src.d_date_sk = d.d_date_sk
JOIN item i                    ON src.i_item_sk = i.i_item_sk
JOIN ship_mode sm              ON src.sm_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w               ON src.w_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer c          ON src.c_customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd ON src.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN time_dim t          ON src.t_time_sk = t.t_time_sk
LEFT JOIN web_site ws         ON src.ws_web_site_sk = ws.web_site_sk
LEFT JOIN call_center cc      ON src.cc_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp      ON src.cp_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN order_diff od        ON src.order_num = od.order_num
FULL OUTER JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
FULL OUTER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category, sm.sm_type, w.w_warehouse_name
ORDER BY total_quantity DESC
LIMIT 100
