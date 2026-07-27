WITH
    joined AS (
        SELECT
            cc.cc_name,
            sm.sm_type,
            r.r_reason_desc,
            w_sales.w_warehouse_name AS sales_warehouse,
            w_inv.w_warehouse_name AS inventory_warehouse,
            cs_bill.cs_net_paid AS net_paid_bill,
            cs_bill.cs_net_profit AS net_profit_bill,
            cs_ship.cs_net_paid AS net_paid_ship,
            cs_ship.cs_net_profit AS net_profit_ship,
            cs_bill.cs_order_number AS order_number_bill,
            cs_ship.cs_order_number AS order_number_ship,
            wr_refund.wr_return_amt AS return_amount,
            inv.inv_quantity_on_hand
        FROM customer c
        JOIN catalog_sales cs_bill
            ON cs_bill.cs_bill_customer_sk = c.c_customer_sk
        JOIN catalog_sales cs_ship
            ON cs_ship.cs_ship_customer_sk = c.c_customer_sk
        JOIN call_center cc
            ON cs_bill.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
            ON cs_ship.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w_sales
            ON cs_bill.cs_warehouse_sk = w_sales.w_warehouse_sk
        LEFT JOIN inventory inv
            ON inv.inv_warehouse_sk = w_sales.w_warehouse_sk
        LEFT JOIN warehouse w_inv
            ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
        LEFT JOIN web_returns wr_refund
            ON wr_refund.wr_refunded_customer_sk = c.c_customer_sk
        LEFT JOIN reason r
            ON wr_refund.wr_reason_sk = r.r_reason_sk
        LEFT JOIN web_returns wr_return
            ON wr_return.wr_returning_customer_sk = c.c_customer_sk
    ),
    agg AS (
        SELECT
            cc_name,
            sm_type,
            r_reason_desc,
            sales_warehouse,
            inventory_warehouse,
            SUM(net_paid_bill) + SUM(net_paid_ship) AS total_sales,
            SUM(net_profit_bill) + SUM(net_profit_ship) AS total_profit,
            SUM(COALESCE(return_amount, 0)) AS total_returns,
            COUNT(DISTINCT order_number_bill) + COUNT(DISTINCT order_number_ship) AS total_orders,
            CASE WHEN SUM(net_profit_bill) + SUM(net_profit_ship) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
        FROM joined
        GROUP BY
            cc_name,
            sm_type,
            r_reason_desc,
            sales_warehouse,
            inventory_warehouse
    )
SELECT
    cc_name,
    sm_type,
    r_reason_desc,
    sales_warehouse,
    inventory_warehouse,
    total_sales,
    total_profit,
    total_returns,
    total_orders,
    profit_status,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
