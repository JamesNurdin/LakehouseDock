WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        hd_bill.hd_buy_potential AS bill_buy_pot,
        hd_ship.hd_buy_potential AS ship_buy_pot,
        cc.cc_name AS call_center_name,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        ss.ss_net_paid AS store_net_paid,
        ss.ss_quantity AS store_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wp.wp_web_page_id
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN tpcds.household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN tpcds.call_center cc2
        ON cr.cr_call_center_sk = cc2.cc_call_center_sk
    LEFT JOIN tpcds.household_demographics hd_wr_refunded
        ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN tpcds.household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
)
SELECT
    i_category,
    bill_buy_pot,
    SUM(cs_net_paid) AS total_sales,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_returns,
    SUM(COALESCE(store_net_paid, 0)) AS total_store_sales,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM base
GROUP BY GROUPING SETS (
    (i_category, bill_buy_pot),
    (i_category),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
