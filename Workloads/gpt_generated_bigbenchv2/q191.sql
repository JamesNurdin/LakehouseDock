WITH combined_sales AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_quantity * i.i_price AS sales_amount
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_quantity * i.i_price AS sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
customer_sales AS (
    SELECT
        cs.customer_id,
        SUM(cs.sales_amount) AS total_sales_amount
    FROM combined_sales cs
    GROUP BY cs.customer_id
),
ranked_customers AS (
    SELECT
        cs.customer_id,
        cs.total_sales_amount,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales_amount DESC) AS sales_rank
    FROM customer_sales cs
)
SELECT
    rc.sales_rank,
    c.c_customer_id,
    c.c_name,
    rc.total_sales_amount
FROM ranked_customers rc
JOIN customers c ON c.c_customer_id = rc.customer_id
WHERE rc.sales_rank <= 10
ORDER BY rc.sales_rank
