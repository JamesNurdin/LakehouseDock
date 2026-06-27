WITH sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(CASE WHEN src = 'store' THEN quantity ELSE 0 END) AS total_store_quantity,
        SUM(CASE WHEN src = 'web'   THEN quantity ELSE 0 END) AS total_web_quantity,
        SUM(quantity)                                        AS total_quantity,
        COUNT(DISTINCT c_customer_id)                        AS distinct_customers
    FROM (
        SELECT ss.ss_item_id   AS item_id,
               ss.ss_quantity  AS quantity,
               'store'          AS src,
               ss.ss_customer_id AS c_customer_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id   AS item_id,
               ws.ws_quantity  AS quantity,
               'web'            AS src,
               ws.ws_customer_id AS c_customer_id
        FROM web_sales ws
    ) s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.i_category_id,
    s.i_category_name,
    s.total_store_quantity,
    s.total_web_quantity,
    s.total_quantity,
    s.distinct_customers,
    r.avg_rating
FROM sales s
LEFT JOIN rating r
    ON s.i_category_id   = r.i_category_id
   AND s.i_category_name = r.i_category_name
ORDER BY s.total_quantity DESC
