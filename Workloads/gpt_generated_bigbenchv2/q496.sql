WITH store_sales_items_agg AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_amount,
        AVG(pr.pr_rating) AS avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
    GROUP BY ss.ss_store_id
),
store_customers AS (
    SELECT DISTINCT
        ss.ss_store_id,
        ss.ss_customer_id
    FROM store_sales ss
),
store_customer_counts AS (
    SELECT
        sc.ss_store_id,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM store_customers sc
    JOIN customers c ON sc.ss_customer_id = c.c_customer_id
    GROUP BY sc.ss_store_id
),
online_sales_by_store_customers AS (
    SELECT
        sc.ss_store_id,
        SUM(ws.ws_quantity) AS total_online_quantity
    FROM store_customers sc
    JOIN customers c ON sc.ss_customer_id = c.c_customer_id
    JOIN web_sales ws ON c.c_customer_id = ws.ws_customer_id
    GROUP BY sc.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ssi.total_quantity,
    COALESCE(os.total_online_quantity, 0) AS total_online_quantity,
    ssi.avg_rating,
    CASE WHEN ssi.total_quantity > 0 THEN ssi.total_sales_amount / ssi.total_quantity ELSE NULL END AS avg_item_price,
    scc.distinct_customers
FROM stores s
LEFT JOIN store_sales_items_agg ssi ON s.s_store_id = ssi.ss_store_id
LEFT JOIN online_sales_by_store_customers os ON s.s_store_id = os.ss_store_id
LEFT JOIN store_customer_counts scc ON s.s_store_id = scc.ss_store_id
ORDER BY ssi.total_quantity DESC NULLS LAST
