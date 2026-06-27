WITH
    store_sales_by_store_category AS (
        SELECT
            s.s_store_id,
            s.s_store_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_qty
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
    ),
    web_sales_by_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_qty
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    reviews_by_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            COUNT(pr.pr_review_id) AS review_cnt,
            AVG(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    price_by_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(i.i_price) AS avg_price,
            AVG(i.i_comp_price) AS avg_comp_price
        FROM items i
        GROUP BY i.i_category_id, i.i_category_name
    ),
    store_sales_ranked AS (
        SELECT
            ss.s_store_name,
            ss.i_category_name,
            ss.store_qty,
            COALESCE(ws.web_qty, 0) AS web_qty,
            ss.store_qty + COALESCE(ws.web_qty, 0) AS total_qty,
            COALESCE(r.review_cnt, 0) AS review_cnt,
            r.avg_rating,
            p.avg_price,
            p.avg_comp_price,
            ROW_NUMBER() OVER (
                PARTITION BY ss.i_category_name
                ORDER BY ss.store_qty + COALESCE(ws.web_qty, 0) DESC
            ) AS rn
        FROM store_sales_by_store_category ss
        LEFT JOIN web_sales_by_category ws ON ss.i_category_id = ws.i_category_id
        LEFT JOIN reviews_by_category r ON ss.i_category_id = r.i_category_id
        LEFT JOIN price_by_category p ON ss.i_category_id = p.i_category_id
    )
SELECT
    s_store_name,
    i_category_name,
    store_qty,
    web_qty,
    total_qty,
    review_cnt,
    avg_rating,
    avg_price,
    avg_comp_price
FROM store_sales_ranked
WHERE rn <= 3
ORDER BY i_category_name, total_qty DESC
