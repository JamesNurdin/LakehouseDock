WITH store_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'High' ELSE 'Low' END AS sales_group,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rank_in_category
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_current_price > 10
    GROUP BY ss.ss_item_sk, i.i_category
    HAVING SUM(ss.ss_ext_sales_price) > 5000
),
web_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_quantity) > 100 THEN 'High' ELSE 'Low' END AS sales_group,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_in_category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20
    GROUP BY ws.ws_item_sk, i.i_category
    HAVING SUM(ws.ws_ext_sales_price) > 3000
),
unsold_items AS (
    SELECT i.i_item_sk AS item_sk
    FROM item i
    WHERE i.i_item_sk NOT IN (SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_ext_sales_price > 1000)
),
common_items AS (
    SELECT item_sk FROM store_agg
    INTERSECT
    SELECT item_sk FROM web_agg
)
SELECT
    a.item_sk,
    a.category,
    a.total_sales,
    a.sales_group,
    a.rank_in_category,
    (SELECT AVG(b.total_sales) FROM store_agg b WHERE b.category = a.category) AS avg_category_sales
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) a
WHERE a.item_sk IN (SELECT item_sk FROM common_items)
  AND a.item_sk NOT IN (SELECT item_sk FROM unsold_items)
ORDER BY a.total_sales DESC, a.item_sk
LIMIT 100
