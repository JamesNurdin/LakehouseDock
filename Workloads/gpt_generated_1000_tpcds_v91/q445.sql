WITH
    cr_agg AS (
        SELECT
            cr.cr_order_number AS order_number,
            SUM(cr.cr_return_quantity) AS quantity,
            SUM(cr.cr_return_amount) AS amount,
            SUM(cr.cr_net_loss) AS net,
            MIN(cd_refund.cd_gender) AS gender1,
            MIN(cd_return.cd_gender) AS gender2,
            MIN(w_cr.w_warehouse_name) AS warehouse_name
        FROM tpcds.catalog_returns cr TABLESAMPLE BERNOULLI (10)
        JOIN tpcds.customer_demographics cd_refund
            ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
        JOIN tpcds.customer_demographics cd_return
            ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
        JOIN tpcds.warehouse w_cr
            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
        WHERE EXISTS (
            SELECT 1
            FROM tpcds.web_sales ws
            WHERE ws.ws_order_number = cr.cr_order_number
        )
        GROUP BY cr.cr_order_number
    ),
    ws_agg AS (
        SELECT
            ws.ws_order_number AS order_number,
            SUM(ws.ws_quantity) AS quantity,
            SUM(ws.ws_ext_sales_price) AS amount,
            SUM(ws.ws_net_profit) AS net,
            MIN(w_ws.w_warehouse_name) AS warehouse_name,
            MIN(cd_bill.cd_gender) AS gender1,
            MIN(cd_ship.cd_gender) AS gender2
        FROM tpcds.web_sales ws
        JOIN tpcds.customer_demographics cd_bill
            ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN tpcds.customer_demographics cd_ship
            ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN tpcds.web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN tpcds.warehouse w_ws
            ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        GROUP BY ws.ws_order_number
    ),
    wr_agg AS (
        SELECT
            wr.wr_order_number AS order_number,
            SUM(wr.wr_return_quantity) AS return_quantity,
            SUM(wr.wr_return_amt) AS return_amount,
            SUM(wr.wr_net_loss) AS return_net_loss
        FROM tpcds.web_returns wr
        JOIN tpcds.web_sales ws
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
        GROUP BY wr.wr_order_number
    ),
    web_combined AS (
        SELECT
            ws.order_number,
            ws.quantity,
            ws.amount,
            ws.net,
            ws.warehouse_name,
            ws.gender1,
            ws.gender2,
            'web' AS source
        FROM ws_agg ws
        LEFT JOIN wr_agg wr
            ON ws.order_number = wr.order_number
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY combined.order_number) AS row_num,
    combined.order_number,
    combined.quantity,
    combined.amount,
    combined.net,
    combined.warehouse_name,
    combined.gender1,
    combined.gender2,
    combined.source,
    (SELECT COUNT(*) FROM tpcds.web_page) AS total_pages
FROM (
    SELECT
        order_number,
        quantity,
        amount,
        net,
        warehouse_name,
        gender1,
        gender2,
        'catalog' AS source
    FROM cr_agg
    UNION
    SELECT
        order_number,
        quantity,
        amount,
        net,
        warehouse_name,
        gender1,
        gender2,
        source
    FROM web_combined
) AS combined
ORDER BY combined.order_number
LIMIT 100
