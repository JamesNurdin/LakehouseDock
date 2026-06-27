WITH
    store_sales_agg AS (
        SELECT i.i_category_id,
               i.i_category_name,
               SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT i.i_category_id,
               i.i_category_name,
               SUM(ws.ws_quantity) AS web_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    rating_agg AS (
        SELECT i.i_category_id,
               i.i_category_name,
               AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    customer_agg AS (
        SELECT c.i_category_id,
               c.i_category_name,
               COUNT(DISTINCT c.c_customer_id) AS distinct_customers
        FROM (
            SELECT ss.ss_customer_id AS c_customer_id,
                   i.i_category_id,
                   i.i_category_name
            FROM store_sales ss
            JOIN items i ON ss.ss_item_id = i.i_item_id
            UNION
            SELECT ws.ws_customer_id AS c_customer_id,
                   i.i_category_id,
                   i.i_category_name
            FROM web_sales ws
            JOIN items i ON ws.ws_item_id = i.i_item_id
        ) c
        GROUP BY c.i_category_id, c.i_category_name
    ),
    categories AS (
        SELECT DISTINCT i_category_id,
               i_category_name
        FROM items
    )
SELECT
    cat.i_category_id,
    cat.i_category_name,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    r.avg_rating,
    cu.distinct_customers
FROM categories cat
LEFT JOIN store_sales_agg s ON cat.i_category_id = s.i_category_id
LEFT JOIN web_sales_agg w ON cat.i_category_id = w.i_category_id
LEFT JOIN rating_agg r ON cat.i_category_id = r.i_category_id
LEFT JOIN customer_agg cu ON cat.i_category_id = cu.i_category_id
ORDER BY cat.i_category_id
