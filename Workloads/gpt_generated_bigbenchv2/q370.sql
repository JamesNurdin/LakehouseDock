WITH sales_customer AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_customer_id,
        SUM(ss.ss_quantity * i.i_price) AS cust_revenue,
        SUM(ss.ss_quantity) AS cust_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    WHERE ss.ss_quantity > 0
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name, ss.ss_customer_id
),
category_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS category_revenue,
        SUM(ss.ss_quantity) AS category_quantity,
        AVG(i.i_price) AS avg_item_price,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    WHERE ss.ss_quantity > 0
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
top_customers AS (
    SELECT
        sc.ss_store_id,
        sc.i_category_id,
        sc.i_category_name,
        sc.ss_customer_id,
        c.c_name,
        sc.cust_revenue,
        sc.cust_quantity,
        ROW_NUMBER() OVER (PARTITION BY sc.ss_store_id, sc.i_category_id ORDER BY sc.cust_revenue DESC) AS cust_rank
    FROM sales_customer sc
    JOIN customers c ON sc.ss_customer_id = c.c_customer_id
)
SELECT
    s.s_store_name,
    cs.i_category_name,
    cs.category_revenue,
    cs.category_quantity,
    cs.avg_item_price,
    cs.distinct_customers,
    tc.c_name AS top_customer_name,
    tc.cust_revenue,
    tc.cust_quantity,
    tc.cust_rank
FROM category_sales cs
JOIN stores s ON cs.ss_store_id = s.s_store_id
LEFT JOIN top_customers tc
    ON cs.ss_store_id = tc.ss_store_id
   AND cs.i_category_id = tc.i_category_id
   AND tc.cust_rank <= 3
ORDER BY cs.category_revenue DESC, tc.cust_rank
LIMIT 100
