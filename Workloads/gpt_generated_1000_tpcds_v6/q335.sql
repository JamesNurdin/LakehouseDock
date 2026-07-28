WITH cust_warehouse_agg AS (
    SELECT
        c.c_customer_id,
        w.w_warehouse_id,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS cnt_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_store_tickets
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    WHERE cs.cs_quantity > 5
      AND c.c_birth_month = 7
      AND cp.cp_department = 'Electronics'
      AND w.w_state = 'CA'
    GROUP BY c.c_customer_id, w.w_warehouse_id
),
warehouse_totals AS (
    SELECT
        w_warehouse_id,
        SUM(total_catalog_sales) AS warehouse_sales_sum,
        AVG(total_catalog_sales) AS warehouse_sales_avg
    FROM cust_warehouse_agg
    GROUP BY w_warehouse_id
    HAVING SUM(total_catalog_sales) > 5000
)
SELECT
    cwa.c_customer_id,
    cwa.w_warehouse_id,
    cwa.total_catalog_sales,
    cwa.total_store_sales,
    cwa.total_returns,
    cwa.cnt_orders,
    cwa.cnt_store_tickets,
    wt.warehouse_sales_sum,
    wt.warehouse_sales_avg,
    ROW_NUMBER() OVER (PARTITION BY cwa.w_warehouse_id ORDER BY cwa.total_catalog_sales DESC) AS rank_in_warehouse
FROM cust_warehouse_agg cwa
JOIN warehouse_totals wt
    ON cwa.w_warehouse_id = wt.w_warehouse_id
WHERE cwa.total_catalog_sales > 1000
ORDER BY cwa.total_catalog_sales DESC
LIMIT 100
