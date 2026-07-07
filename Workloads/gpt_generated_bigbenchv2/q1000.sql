WITH
    categories AS (
        SELECT DISTINCT i.i_category
        FROM items i
    ),
    store_qty_agg AS (
        SELECT i.i_category,
               SUM(ss.ss_quantity) AS total_store_qty,
               COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
        FROM store_sales ss
        JOIN items i
          ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    web_qty_agg AS (
        SELECT i.i_category,
               SUM(ws.ws_quantity) AS total_web_qty,
               COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
        FROM web_sales ws
        JOIN items i
          ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    review_agg AS (
        SELECT i.i_category,
               AVG(pr.pr_sentiment) AS avg_sentiment,
               AVG(i.i_price) AS avg_item_price,
               COUNT(*) AS review_cnt
        FROM product_reviews pr
        JOIN items i
          ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category
    ),
    customer_agg AS (
        SELECT i.i_category,
               COUNT(DISTINCT c.c_customer_id) AS distinct_customers
        FROM (
            SELECT ss.ss_customer_id AS cust_id, ss.ss_item_id AS item_id
            FROM store_sales ss
            UNION ALL
            SELECT ws.ws_customer_id AS cust_id, ws.ws_item_id AS item_id
            FROM web_sales ws
        ) sc
        JOIN items i
          ON sc.item_id = i.i_item_id
        JOIN customers c
          ON sc.cust_id = c.c_customer_id
        GROUP BY i.i_category
    )
SELECT cat.i_category,
       COALESCE(s.total_store_qty, 0) + COALESCE(w.total_web_qty, 0) AS total_quantity_sold,
       COALESCE(r.avg_item_price, 0) AS avg_item_price,
       COALESCE(r.avg_sentiment, 0) AS avg_review_sentiment,
       COALESCE(ca.distinct_customers, 0) AS distinct_customers
FROM categories cat
LEFT JOIN store_qty_agg s
  ON cat.i_category = s.i_category
LEFT JOIN web_qty_agg w
  ON cat.i_category = w.i_category
LEFT JOIN review_agg r
  ON cat.i_category = r.i_category
LEFT JOIN customer_agg ca
  ON cat.i_category = ca.i_category
ORDER BY total_quantity_sold DESC
LIMIT 20
