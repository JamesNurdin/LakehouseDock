WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_sales
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_item_sales AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_sales
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
joined_data AS (
    SELECT
        s.s_store_name,
        i.i_name,
        i.i_category_name,
        si.total_store_quantity,
        si.total_store_sales,
        wi.total_web_quantity,
        wi.total_web_sales,
        ir.avg_rating,
        ir.review_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY si.total_store_sales DESC) AS rank_per_store
    FROM store_item_sales si
    JOIN stores s ON si.ss_store_id = s.s_store_id
    JOIN items i ON si.ss_item_id = i.i_item_id
    LEFT JOIN web_item_sales wi ON si.ss_item_id = wi.ws_item_id
    LEFT JOIN item_reviews ir ON si.ss_item_id = ir.pr_item_id
)
SELECT
    s_store_name,
    i_name,
    i_category_name,
    total_store_quantity,
    total_store_sales,
    total_web_quantity,
    total_web_sales,
    avg_rating,
    review_count,
    rank_per_store
FROM joined_data
WHERE rank_per_store <= 5
ORDER BY s_store_name, rank_per_store
