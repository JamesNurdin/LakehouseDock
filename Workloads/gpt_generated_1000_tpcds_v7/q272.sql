WITH
joined AS (
    SELECT
        cc.cc_name,
        wp.wp_type,
        ws.ws_order_number,
        ws.ws_net_paid,
        cr.cr_return_amount,
        sr.sr_return_amt
    FROM
        web_sales ws
        JOIN customer_demographics cd_bill
            ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship
            ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN household_demographics hd_bill
            ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship
            ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN store_returns sr
            ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
               AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
),
aggregated AS (
    SELECT
        cc_name,
        wp_type,
        COUNT(DISTINCT ws_order_number) AS orders,
        SUM(ws_net_paid) AS total_sales,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(sr_return_amt) AS total_store_return,
        SUM(ws_net_paid) - COALESCE(SUM(cr_return_amount), 0) - COALESCE(SUM(sr_return_amt), 0) AS net_revenue
    FROM joined
    GROUP BY cc_name, wp_type
)
SELECT
    cc_name,
    wp_type,
    orders,
    total_sales,
    total_catalog_return,
    total_store_return,
    net_revenue,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY net_revenue DESC, cc_name
LIMIT 100
