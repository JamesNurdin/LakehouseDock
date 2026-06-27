WITH
    sales_union AS (
        SELECT ss_customer_id AS customer_id,
               ss_item_id AS item_id,
               ss_quantity AS quantity
        FROM store_sales
        UNION ALL
        SELECT ws_customer_id AS customer_id,
               ws_item_id AS item_id,
               ws_quantity AS quantity
        FROM web_sales
    ),
    item_sales AS (
        SELECT i.i_item_id,
               i.i_name,
               i.i_category_id,
               i.i_category_name,
               i.i_price,
               SUM(s.quantity) AS total_quantity,
               SUM(s.quantity * i.i_price) AS total_revenue,
               COUNT(DISTINCT s.customer_id) AS distinct_customers
        FROM sales_union s
        JOIN items i
          ON s.item_id = i.i_item_id
        GROUP BY i.i_item_id,
                 i.i_name,
                 i.i_category_id,
                 i.i_category_name,
                 i.i_price
    ),
    item_reviews AS (
        SELECT i.i_item_id,
               AVG(pr.pr_rating) AS avg_rating,
               COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i
          ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    item_sales_with_reviews AS (
        SELECT s.i_item_id,
               s.i_name,
               s.i_category_id,
               s.i_category_name,
               s.i_price,
               s.total_quantity,
               s.total_revenue,
               s.distinct_customers,
               COALESCE(r.avg_rating, 0) AS avg_rating,
               COALESCE(r.review_count, 0) AS review_count
        FROM item_sales s
        LEFT JOIN item_reviews r
          ON s.i_item_id = r.i_item_id
    )
SELECT
    ranked.i_category_id,
    ranked.i_category_name,
    ranked.i_item_id,
    ranked.i_name,
    ranked.total_quantity,
    ranked.total_revenue,
    ranked.distinct_customers,
    ranked.avg_rating,
    ranked.review_count,
    ranked.revenue_rank
FROM (
    SELECT
        i.i_category_id,
        i.i_category_name,
        i.i_item_id,
        i.i_name,
        i.total_quantity,
        i.total_revenue,
        i.distinct_customers,
        i.avg_rating,
        i.review_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY i.total_revenue DESC) AS revenue_rank
    FROM item_sales_with_reviews i
) ranked
WHERE ranked.revenue_rank <= 5
ORDER BY ranked.i_category_id, ranked.revenue_rank
