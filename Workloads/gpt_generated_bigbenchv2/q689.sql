-- Customer purchase summary across store and web channels with item‑rating insights
WITH item_rating AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_id   AS customer_id,
        ss.ss_store_id      AS store_id,
        ss.ss_item_id       AS item_id,
        ss.ss_quantity      AS quantity,
        i.i_price           AS price,
        COALESCE(ir.avg_rating, 0) AS rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_rating ir
        ON i.i_item_id = ir.pr_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_customer_id   AS customer_id,
        NULL                AS store_id,
        ws.ws_item_id       AS item_id,
        ws.ws_quantity      AS quantity,
        i.i_price           AS price,
        COALESCE(ir.avg_rating, 0) AS rating
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_rating ir
        ON i.i_item_id = ir.pr_item_id
),
combined_sales AS (
    SELECT
        customer_id,
        store_id,
        item_id,
        quantity,
        price,
        rating
    FROM store_sales_agg
    UNION ALL
    SELECT
        customer_id,
        store_id,
        item_id,
        quantity,
        price,
        rating
    FROM web_sales_agg
)
SELECT
    c.c_customer_id,
    c.c_name,
    SUM(cs.quantity)                                               AS total_quantity,
    SUM(CASE WHEN cs.store_id IS NOT NULL THEN cs.quantity ELSE 0 END) AS total_quantity_store,
    SUM(CASE WHEN cs.store_id IS NULL THEN cs.quantity ELSE 0 END)      AS total_quantity_web,
    COUNT(DISTINCT CASE WHEN cs.store_id IS NOT NULL THEN cs.store_id END) AS distinct_stores,
    COUNT(DISTINCT cs.item_id)                                      AS distinct_items,
    AVG(cs.price)                                                   AS avg_item_price,
    CASE
        WHEN SUM(cs.quantity) > 0 THEN SUM(cs.rating * cs.quantity) / SUM(cs.quantity)
        ELSE NULL
    END                                                            AS weighted_avg_rating
FROM combined_sales cs
JOIN customers c
    ON cs.customer_id = c.c_customer_id
GROUP BY
    c.c_customer_id,
    c.c_name
ORDER BY
    total_quantity DESC
LIMIT 20
