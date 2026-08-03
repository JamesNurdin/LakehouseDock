WITH customer_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(wr.wr_net_loss) AS total_web_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        w.w_warehouse_sk
    FROM customer c
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
    WHERE
        hd.hd_dep_count BETWEEN 3 AND 7
        AND hd.hd_vehicle_count >= 1
        AND cp.cp_department = 'Electronics'
        AND w.w_state = 'CA'
        AND i.inv_quantity_on_hand > 50
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
        AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY c.c_customer_sk, c.c_customer_id, w.w_warehouse_sk
)
SELECT
    ca.c_customer_id,
    ca.total_store_sales,
    ca.total_catalog_sales,
    ca.total_web_loss,
    ca.total_inventory_qty,
    RANK() OVER (ORDER BY (ca.total_store_sales + ca.total_catalog_sales) DESC) AS sales_rank,
    (
        SELECT SUM(i2.inv_quantity_on_hand)
        FROM inventory i2
        WHERE i2.inv_warehouse_sk = ca.w_warehouse_sk
    ) AS warehouse_total_inventory,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = ca.c_customer_sk
          AND sr3.sr_net_loss > 100
    ) THEN 1 ELSE 0 END AS high_loss_return_flag
FROM customer_agg ca
WHERE (ca.total_store_sales + ca.total_catalog_sales) > 1000
ORDER BY sales_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
