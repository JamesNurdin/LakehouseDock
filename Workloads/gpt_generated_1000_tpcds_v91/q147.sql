/* Goal: Analyze the combined effect of call center locations, return reasons, and warehouses on return amounts, sales, and inventory, providing subtotals, rankings, and warehouse‑level return counts. */
WITH base_data AS (
    SELECT
        cc.cc_state,
        r.r_reason_desc,
        cr.cr_return_amount,
        ss.ss_net_paid,
        i.inv_quantity_on_hand,
        ss.ss_ticket_number,
        cr.cr_order_number,
        w.w_warehouse_sk,
        cust_sales.c_customer_sk
    FROM store_sales ss
    JOIN customer cust_sales
        ON ss.ss_customer_sk = cust_sales.c_customer_sk
    JOIN customer_demographics cd_sales
        ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN household_demographics hd_sales
        ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_returning_customer_sk = cust_sales.c_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    FULL OUTER JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer cust_refunded
        ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer_demographics cd_current
        ON cust_sales.c_current_cdemo_sk = cd_current.cd_demo_sk
    JOIN household_demographics hd_current
        ON cust_sales.c_current_hdemo_sk = hd_current.hd_demo_sk
),
aggregated AS (
    SELECT
        cc_state,
        r_reason_desc,
        w_warehouse_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ss_net_paid) AS total_sales,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT ss_ticket_number) AS num_sales_transactions,
        COUNT(DISTINCT cr_order_number) AS num_return_transactions
    FROM base_data
    GROUP BY GROUPING SETS (
        (cc_state, r_reason_desc, w_warehouse_sk),
        (cc_state, r_reason_desc),
        (cc_state),
        (r_reason_desc),
        (w_warehouse_sk),
        ()
    )
)
SELECT
    cc_state,
    r_reason_desc,
    w_warehouse_sk,
    total_return_amount,
    total_sales,
    total_inventory,
    num_sales_transactions,
    num_return_transactions,
    ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY total_return_amount DESC) AS rn_state_return_rank,
    (SELECT COUNT(*) FROM catalog_returns cr_sub WHERE cr_sub.cr_warehouse_sk = agg.w_warehouse_sk) AS returns_per_warehouse
FROM aggregated agg
WHERE total_return_amount > (
    SELECT AVG(cr2.cr_return_amount)
    FROM catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = agg.w_warehouse_sk
)
ORDER BY total_return_amount DESC
LIMIT 100
