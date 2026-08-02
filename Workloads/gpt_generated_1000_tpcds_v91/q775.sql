WITH store_items AS (
    SELECT i.i_item_id,
           i.i_item_sk,
           i.i_current_price,
           SUM(ss.ss_ext_sales_price) AS store_sales_total,
           COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
      AND i.i_manufact_id = 214
    GROUP BY i.i_item_id, i.i_item_sk, i.i_current_price
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
web_items AS (
    SELECT i.i_item_id,
           i.i_item_sk,
           i.i_current_price,
           SUM(ws.ws_ext_sales_price) AS web_sales_total,
           COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_color = 'turquoise'
      AND ws.ws_quantity > 1
    GROUP BY i.i_item_id, i.i_item_sk, i.i_current_price
    HAVING SUM(ws.ws_ext_sales_price) > 8000
),
intersect_items AS (
    SELECT i_item_id
    FROM store_items
    INTERSECT
    SELECT i_item_id
    FROM web_items
)
SELECT i.i_item_id,
       i.i_current_price,
       (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk) AS store_return_count
FROM intersect_items ii
JOIN item i ON i.i_item_id = ii.i_item_id
ORDER BY i.i_item_id
LIMIT 100
