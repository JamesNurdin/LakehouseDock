WITH
    store_sales_agg AS (
        SELECT
            ss_item_id AS i_item_id,
            SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id AS i_item_id,
            SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    item_sales AS (
        SELECT
            i.i_item_id,
            i.i_category_id,
            i.i_category_name,
            i.i_price,
            i.i_comp_price,
            COALESCE(ss.store_quantity, 0) AS store_quantity,
            COALESCE(ws.web_quantity, 0) AS web_quantity
        FROM items i
        LEFT JOIN store_sales_agg ss ON ss.i_item_id = i.i_item_id
        LEFT JOIN web_sales_agg ws ON ws.i_item_id = i.i_item_id
    ),
    item_reviews AS (
        SELECT
            pr.pr_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    isales.i_category_name,
    COUNT(DISTINCT isales.i_item_id) AS num_items,
    SUM(isales.store_quantity + isales.web_quantity) AS total_quantity_sold,
    AVG(isales.i_price) AS avg_price,
    AVG(COALESCE(irev.avg_rating, 0)) AS avg_item_rating,
    SUM(isales.store_quantity * isales.i_price + isales.web_quantity * isales.i_price) AS total_sales_amount,
    SUM(COALESCE(irev.review_count, 0)) AS total_reviews
FROM item_sales isales
LEFT JOIN item_reviews irev ON irev.pr_item_id = isales.i_item_id
GROUP BY isales.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 10
