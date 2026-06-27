WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_enriched AS (
    SELECT ss.ss_store_id,
           ss.ss_customer_id,
           ss.ss_quantity,
           i.i_price,
           i.i_category_id,
           i.i_category_name,
           ir.avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
store_category_revenue AS (
    SELECT ss_en.ss_store_id,
           ss_en.i_category_id,
           ss_en.i_category_name,
           SUM(ss_en.ss_quantity * ss_en.i_price) AS category_revenue
    FROM store_sales_enriched ss_en
    GROUP BY ss_en.ss_store_id, ss_en.i_category_id, ss_en.i_category_name
),
store_top_category AS (
    SELECT store_id,
           i_category_name AS top_category,
           category_revenue
    FROM (
        SELECT sscr.ss_store_id AS store_id,
               sscr.i_category_name,
               sscr.category_revenue,
               ROW_NUMBER() OVER (PARTITION BY sscr.ss_store_id ORDER BY sscr.category_revenue DESC) AS rn
        FROM store_category_revenue sscr
    ) ranked
    WHERE rn = 1
)
SELECT s.s_store_id,
       s.s_store_name,
       COALESCE(SUM(ss_en.ss_quantity * ss_en.i_price), 0) AS total_sales_revenue,
       COALESCE(SUM(ss_en.ss_quantity), 0) AS total_items_sold,
       COUNT(DISTINCT ss_en.ss_customer_id) AS distinct_customers,
       COALESCE(
           SUM(ss_en.avg_rating * ss_en.ss_quantity) / NULLIF(SUM(ss_en.ss_quantity), 0),
           NULL
       ) AS weighted_avg_rating,
       tc.top_category,
       tc.category_revenue AS top_category_revenue
FROM stores s
LEFT JOIN store_sales_enriched ss_en ON s.s_store_id = ss_en.ss_store_id
LEFT JOIN store_top_category tc ON s.s_store_id = tc.store_id
GROUP BY s.s_store_id, s.s_store_name, tc.top_category, tc.category_revenue
ORDER BY total_sales_revenue DESC
