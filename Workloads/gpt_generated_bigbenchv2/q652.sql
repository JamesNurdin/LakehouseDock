WITH
item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        NULL AS ss_store_id,
        ws.ws_item_id AS ss_item_id,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
combined_sales AS (
    SELECT
        ss_store_id,
        ss_item_id,
        quantity
    FROM store_sales_agg
    UNION ALL
    SELECT
        ss_store_id,
        ss_item_id,
        quantity
    FROM web_sales_agg
),
sales_by_store_item AS (
    SELECT
        cs.ss_store_id,
        cs.ss_item_id,
        SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    GROUP BY cs.ss_store_id, cs.ss_item_id
),
ranked_sales AS (
    SELECT
        sbsi.ss_store_id,
        sbsi.ss_item_id,
        sbsi.total_quantity,
        i.i_item_id AS i_item_id,
        i.i_name,
        i.i_category_name,
        ir.avg_rating,
        ROW_NUMBER() OVER (PARTITION BY sbsi.ss_store_id ORDER BY sbsi.total_quantity DESC) AS rnk
    FROM sales_by_store_item sbsi
    JOIN items i
        ON sbsi.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.i_item_id
)
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    rs.i_item_id,
    rs.i_name,
    rs.i_category_name,
    rs.total_quantity,
    rs.avg_rating
FROM ranked_sales rs
LEFT JOIN stores s
    ON rs.ss_store_id = s.s_store_id
WHERE rs.rnk <= 5
ORDER BY store_name, rs.rnk
