WITH ws_items AS (
    SELECT DISTINCT i.i_item_id AS item_id,
        (SELECT avg(ws_ext_sales_price) FROM web_sales) AS avg_sales_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    )
      AND ws.ws_sold_date_sk BETWEEN 2451080 AND 2451100
),
cs_items AS (
    SELECT DISTINCT i2.i_item_id AS item_id,
        (SELECT avg(ws_ext_sales_price) FROM web_sales) AS avg_sales_price
    FROM catalog_sales cs
    RIGHT OUTER JOIN item i2
        ON cs.cs_item_sk = i2.i_item_sk
        AND cs.cs_sold_date_sk BETWEEN 2451080 AND 2451100
    WHERE EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
    )
)
SELECT item_id, avg_sales_price
FROM ws_items
INTERSECT
SELECT item_id, avg_sales_price
FROM cs_items
ORDER BY item_id
OFFSET 0
LIMIT 100
