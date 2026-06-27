/*
  Analytical query: revenue, sales volume, distinct customers, and weighted average product rating per store.
  Uses only the allowed tables and join rules.
*/
WITH item_ratings AS (
    SELECT
        pr_item_id AS i_item_id,
        avg(pr_rating) AS avg_rating,
        count(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_enriched AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        r.avg_rating,
        r.review_count
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    LEFT JOIN item_ratings r
        ON i.i_item_id = r.i_item_id
)
SELECT
    sse.ss_store_id,
    sse.s_store_name,
    sum(sse.ss_quantity) AS total_quantity_sold,
    sum(sse.ss_quantity * sse.i_price) AS total_revenue,
    count(DISTINCT sse.ss_customer_id) AS distinct_customer_count,
    sum(sse.ss_quantity * sse.avg_rating) / nullif(sum(sse.ss_quantity), 0) AS weighted_avg_rating,
    sum(sse.review_count) AS total_review_count
FROM store_sales_enriched sse
GROUP BY sse.ss_store_id, sse.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
