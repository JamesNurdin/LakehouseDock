WITH base AS (
    SELECT
        s.s_store_name,
        cc.cc_name AS call_center_name,
        sm1.sm_type AS catalog_ship_mode,
        sm2.sm_type AS web_ship_mode,
        CASE WHEN ws.ws_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT c_refund.c_customer_sk) AS distinct_refunded_customers,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
    FROM
        catalog_returns cr
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w1
            ON cr.cr_warehouse_sk = w1.w_warehouse_sk
        JOIN ship_mode sm1
            ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
        JOIN reason r1
            ON cr.cr_reason_sk = r1.r_reason_sk
        JOIN customer c_refund
            ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
        JOIN customer c_return
            ON cr.cr_returning_customer_sk = c_return.c_customer_sk
        JOIN item i1
            ON cr.cr_item_sk = i1.i_item_sk
        JOIN store_returns sr
            ON sr.sr_item_sk = i1.i_item_sk
        JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r2
            ON sr.sr_reason_sk = r2.r_reason_sk
        JOIN customer c_sr
            ON sr.sr_customer_sk = c_sr.c_customer_sk
        JOIN web_sales ws
            ON ws.ws_item_sk = i1.i_item_sk
        JOIN ship_mode sm2
            ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN warehouse w2
            ON ws.ws_warehouse_sk = w2.w_warehouse_sk
        JOIN customer c_ws
            ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    WHERE
        EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND sr2.sr_return_quantity > 5
        )
    GROUP BY
        s.s_store_name,
        cc.cc_name,
        sm1.sm_type,
        sm2.sm_type,
        CASE WHEN ws.ws_net_profit > 100 THEN 'High' ELSE 'Low' END
)
SELECT
    base.*,
    ROW_NUMBER() OVER (ORDER BY base.total_web_sales DESC) AS sales_rank
FROM base
ORDER BY base.total_web_sales DESC
LIMIT 100
