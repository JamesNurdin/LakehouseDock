WITH
    item_ratings AS (
        SELECT i.i_item_id,
               AVG(pr.pr_rating) AS avg_rating
        FROM items i
        JOIN product_reviews pr
          ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    store_sales_agg AS (
        SELECT ss.ss_customer_id AS customer_id,
               ss.ss_item_id    AS item_id,
               SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        GROUP BY ss.ss_customer_id, ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT ws.ws_customer_id AS customer_id,
               ws.ws_item_id    AS item_id,
               SUM(ws.ws_quantity) AS web_quantity
        FROM web_sales ws
        GROUP BY ws.ws_customer_id, ws.ws_item_id
    ),
    combined_sales AS (
        SELECT COALESCE(ssa.customer_id, wsa.customer_id) AS customer_id,
               COALESCE(ssa.item_id,    wsa.item_id)    AS item_id,
               COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity
        FROM store_sales_agg ssa
        FULL OUTER JOIN web_sales_agg wsa
          ON ssa.customer_id = wsa.customer_id
         AND ssa.item_id    = wsa.item_id
    )
SELECT
    c.c_customer_id                                   AS customer_id,
    c.c_name                                         AS customer_name,
    SUM(cs.total_quantity)                           AS total_quantity,
    SUM(cs.total_quantity * i.i_price)               AS total_spend,
    COUNT(DISTINCT i.i_item_id)                       AS distinct_items_purchased,
    CASE WHEN SUM(cs.total_quantity) > 0
         THEN SUM(cs.total_quantity * COALESCE(ir.avg_rating, 0)) / SUM(cs.total_quantity)
         ELSE NULL
    END                                               AS weighted_avg_item_rating
FROM combined_sales cs
JOIN customers c
  ON cs.customer_id = c.c_customer_id
JOIN items i
  ON cs.item_id = i.i_item_id
LEFT JOIN item_ratings ir
  ON i.i_item_id = ir.i_item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spend DESC
LIMIT 10
