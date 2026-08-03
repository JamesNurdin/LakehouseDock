WITH catalog_rev AS (
    SELECT
        c.c_customer_id,
        SUM(cs.cs_net_paid) AS total_revenue
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND cs.cs_ext_discount_amt > 500
      AND EXISTS (
            SELECT 1
            FROM inventory i
            JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
            WHERE i.inv_date_sk = cs.cs_sold_date_sk
              AND i.inv_item_sk = cs.cs_item_sk
              AND i.inv_quantity_on_hand > 0
        )
    GROUP BY c.c_customer_id
),
store_rev AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ss.ss_ext_discount_amt > 500
      AND EXISTS (
            SELECT 1
            FROM inventory i
            JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
            WHERE i.inv_date_sk = ss.ss_sold_date_sk
              AND i.inv_item_sk = ss.ss_item_sk
              AND i.inv_quantity_on_hand > 0
        )
    GROUP BY c.c_customer_id
)
SELECT combined.c_customer_id,
       combined.total_revenue
FROM (
    SELECT cr.c_customer_id, cr.total_revenue
    FROM catalog_rev cr
    UNION ALL
    SELECT sr.c_customer_id, sr.total_revenue
    FROM store_rev sr
) AS combined
ORDER BY combined.total_revenue DESC
LIMIT 100
