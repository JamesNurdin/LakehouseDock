WITH catalog_subset AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_quantity AS qty
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (5)
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_subset AS (
    SELECT ws.ws_item_sk AS item_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_quantity AS qty
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_list_price > 6000
),
common_keys AS (
    SELECT item_sk, date_sk FROM catalog_subset
    INTERSECT
    SELECT item_sk, date_sk FROM web_subset
),
returns_keys AS (
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_returned_date_sk AS date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
final_set AS (
    SELECT cs.item_sk,
           cs.date_sk,
           'catalog' AS src,
           cs.qty
    FROM catalog_subset cs
    EXCEPT
    SELECT r.item_sk,
           r.date_sk,
           NULL,
           NULL
    FROM returns_keys r
    UNION
    SELECT ws.item_sk,
           ws.date_sk,
           'web' AS src,
           ws.qty
    FROM web_subset ws
    EXCEPT
    SELECT r.item_sk,
           r.date_sk,
           NULL,
           NULL
    FROM returns_keys r
)
SELECT f.item_sk,
       f.date_sk,
       CASE WHEN f.src = 'catalog' THEN 'Catalog' ELSE 'Web' END AS sale_channel,
       SUM(f.qty) AS total_quantity,
       (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = f.date_sk) AS sale_date
FROM final_set f
WHERE (f.item_sk, f.date_sk) IN (SELECT item_sk, date_sk FROM common_keys)
GROUP BY f.item_sk, f.date_sk, f.src
ORDER BY total_quantity DESC, f.item_sk
LIMIT 100
