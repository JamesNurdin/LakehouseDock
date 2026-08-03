WITH store_items AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i)large')
),
web_items AS (
    SELECT DISTINCT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i)large')
      AND p.p_promo_name LIKE '%discount%'
),
intersect_items AS (
    SELECT item_sk FROM store_items
    INTERSECT
    SELECT item_sk FROM web_items
),
store_agg AS (
    SELECT ss.ss_item_sk AS item_sk,
           SUM(ss.ss_ext_sales_price) AS store_sales_total,
           COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_item_sk
),
web_agg AS (
    SELECT ws.ws_item_sk AS item_sk,
           SUM(ws.ws_ext_sales_price) AS web_sales_total,
           COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_item_sk
)
SELECT
    i.i_item_sk,
    concat(i.i_brand, ' ', i.i_product_name) AS full_product_name,
    regexp_extract(i.i_item_desc, '(\\d+)', 1) AS numeric_code,
    COALESCE(s.store_sales_total, 0) AS store_sales_total,
    COALESCE(w.web_sales_total, 0) AS web_sales_total,
    CASE
        WHEN COALESCE(s.store_sales_total, 0) > COALESCE(w.web_sales_total, 0) THEN 'Store'
        ELSE 'Web'
    END AS higher_channel,
    ROW_NUMBER() OVER (ORDER BY COALESCE(s.store_sales_total, 0) DESC) AS rn
FROM intersect_items ii
JOIN item i ON ii.item_sk = i.i_item_sk
LEFT JOIN store_agg s ON ii.item_sk = s.item_sk
LEFT JOIN web_agg w ON ii.item_sk = w.item_sk
ORDER BY rn
LIMIT 100
