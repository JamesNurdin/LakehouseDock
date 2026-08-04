/* goal: Identify dates where both catalog and web sales generated high net profit for Electronics items, using sampled data and lateral subqueries, and intersect the resulting date sets */
SELECT sales_date
FROM (
        SELECT d.d_date AS sales_date
        FROM (
                SELECT *
                FROM catalog_sales
                TABLESAMPLE BERNOULLI (10)
            ) cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        CROSS JOIN LATERAL (
            SELECT max(cs2.cs_order_number) AS max_order_number
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = d.d_date_sk
        ) lo
        WHERE i.i_category = 'Electronics'
        GROUP BY d.d_date
        HAVING sum(cs.cs_net_profit) > 10000
    )
INTERSECT
    SELECT d.d_date AS sales_date
    FROM (
            SELECT *
            FROM web_sales
            TABLESAMPLE BERNOULLI (10)
        ) ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT max(ws2.ws_order_number) AS max_order_number
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = d.d_date_sk
    ) lo2
    WHERE i.i_category = 'Electronics'
    GROUP BY d.d_date
    HAVING sum(ws.ws_net_profit) > 8000
ORDER BY sales_date
