WITH store_items AS (
    SELECT ss.ss_item_sk AS item_sk,
           d.d_year AS sales_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_items AS (
    SELECT ws.ws_item_sk AS item_sk,
           d.d_year AS sales_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returned_items AS (
    SELECT sr.sr_item_sk AS item_sk,
           d.d_year AS sales_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT item_sk,
       sales_year
FROM (
    SELECT item_sk,
           sales_year
    FROM store_items
    INTERSECT
    SELECT item_sk,
           sales_year
    FROM web_items
) AS intersected_items
EXCEPT
SELECT item_sk,
       sales_year
FROM returned_items
ORDER BY item_sk
LIMIT 100
