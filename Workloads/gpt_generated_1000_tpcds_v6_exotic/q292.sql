WITH filtered_items AS (
    SELECT i_item_sk, i_category
    FROM item
    WHERE i_current_price > 10
)
SELECT
    fi.i_category AS category,
    'Store' AS channel,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_quantity) AS total_quantity,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
FROM store_sales ss
JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
GROUP BY fi.i_category
UNION ALL
SELECT
    fi.i_category AS category,
    'Web' AS channel,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    SUM(ws.ws_quantity) AS total_quantity,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
FROM web_sales ws
JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE w.web_state = 'CA'
GROUP BY fi.i_category
LIMIT 100
