WITH category_sales AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category

    UNION ALL

    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_sales_agg AS (
    SELECT i_category_id,
           i_category,
           SUM(total_quantity) AS total_quantity
    FROM category_sales
    GROUP BY i_category_id, i_category
),
category_price AS (
    SELECT i_category_id,
           i_category,
           AVG(i_price) AS avg_price
    FROM items
    GROUP BY i_category_id, i_category
),
category_sentiment AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT cs.i_category_id,
       cs.i_category,
       cs.total_quantity,
       cp.avg_price,
       csent.avg_sentiment
FROM category_sales_agg cs
JOIN category_price cp
  ON cs.i_category_id = cp.i_category_id
 AND cs.i_category = cp.i_category
JOIN category_sentiment csent
  ON cs.i_category_id = csent.i_category_id
 AND cs.i_category = csent.i_category
ORDER BY cs.total_quantity DESC
