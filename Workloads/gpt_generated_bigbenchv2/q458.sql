WITH sales_store AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category
),

sales_web AS (
    SELECT
        'Online' AS store_name,
        i.i_category AS category,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),

sales_combined AS (
    SELECT store_name, category, total_quantity FROM sales_store
    UNION ALL
    SELECT store_name, category, total_quantity FROM sales_web
),

category_sentiment AS (
    SELECT
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),

sales_ranked AS (
    SELECT
        sc.store_name,
        sc.category,
        sc.total_quantity,
        cs.avg_sentiment,
        ROW_NUMBER() OVER (PARTITION BY sc.store_name ORDER BY sc.total_quantity DESC) AS category_rank
    FROM sales_combined sc
    LEFT JOIN category_sentiment cs ON sc.category = cs.category
)
SELECT
    store_name,
    category,
    total_quantity,
    avg_sentiment
FROM sales_ranked
WHERE category_rank <= 3
ORDER BY store_name, total_quantity DESC
