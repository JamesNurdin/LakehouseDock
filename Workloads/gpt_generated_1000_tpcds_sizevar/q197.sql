WITH eligible_customers AS (
    SELECT sr_customer_sk AS c_customer_sk
    FROM store_returns
    WHERE sr_fee < 20
    GROUP BY sr_customer_sk
    INTERSECT
    SELECT cs_bill_customer_sk
    FROM catalog_sales
    WHERE cs_net_paid > 1000
),
inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk = 2450822
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_state,
    cp.cp_department,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(sr.sr_net_loss) AS total_returns_loss,
    SUM(inv_agg.total_qty) AS total_inventory_qty,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(cs.cs_net_paid) AS min_sale,
    MAX(cs.cs_net_paid) AS max_sale
FROM eligible_customers ec
JOIN customer c
    ON ec.c_customer_sk = c.c_customer_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t1
    ON cs.cs_sold_time_sk = t1.t_time_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN inv_agg
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cp.cp_department = 'Electronics'
    AND w.w_state = 'CA'
    AND t1.t_hour = 14
    AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450969
GROUP BY
    w.w_warehouse_id,
    w.w_state,
    cp.cp_department
ORDER BY total_sales DESC
LIMIT 100
