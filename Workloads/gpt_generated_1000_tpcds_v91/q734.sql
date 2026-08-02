WITH sales_and_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_bill_customer_sk,
        cc_sales.cc_name AS call_center_name,
        cp_sales.cp_department AS department,
        w_sales.w_warehouse_name AS warehouse_name,
        w_sales.w_warehouse_sk AS warehouse_sk,
        cr.cr_return_amount
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc_sales
        ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
    JOIN tpcds.catalog_page cp_sales
        ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    JOIN tpcds.warehouse w_sales
        ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
    JOIN tpcds.customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.call_center cc_returns
        ON cr.cr_call_center_sk = cc_returns.cc_call_center_sk
    JOIN tpcds.catalog_page cp_returns
        ON cr.cr_catalog_page_sk = cp_returns.cp_catalog_page_sk
    JOIN tpcds.warehouse w_returns
        ON cr.cr_warehouse_sk = w_returns.w_warehouse_sk
    JOIN tpcds.customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN tpcds.customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN tpcds.inventory inv
        ON inv.inv_warehouse_sk = w_sales.w_warehouse_sk
)
SELECT
    call_center_name,
    department,
    warehouse_name,
    COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers,
    SUM(cs_net_paid) AS total_sales_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    (
        SELECT AVG(inv2.inv_quantity_on_hand)
        FROM tpcds.inventory inv2
        WHERE inv2.inv_warehouse_sk = warehouse_sk
    ) AS avg_inventory_quantity_on_hand,
    MAX(
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM tpcds.catalog_returns cr2
                WHERE cr2.cr_order_number = cs_order_number
                  AND cr2.cr_return_amount > cr_return_amount
            ) THEN 1
            ELSE 0
        END
    ) AS has_higher_return_flag
FROM sales_and_returns
WHERE cs_order_number IN (
    SELECT cr2.cr_order_number
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_return_amount > 100
)
GROUP BY
    call_center_name,
    department,
    warehouse_name,
    warehouse_sk
ORDER BY total_sales_net_paid DESC
LIMIT 100
