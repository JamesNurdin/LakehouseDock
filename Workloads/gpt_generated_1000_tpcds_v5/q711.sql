WITH catalog_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
    GROUP BY cs.cs_warehouse_sk, cs.cs_item_sk
),
web_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 1000
    GROUP BY ws.ws_warehouse_sk, ws.ws_item_sk
),
combined AS (
    SELECT
        COALESCE(ca.cs_warehouse_sk, wa.ws_warehouse_sk) AS warehouse_sk,
        COALESCE(ca.cs_item_sk, wa.ws_item_sk) AS item_sk,
        COALESCE(ca.catalog_sales, 0) + COALESCE(wa.web_sales, 0) AS total_sales,
        COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0) AS total_profit
    FROM catalog_agg ca
    FULL OUTER JOIN web_agg wa
        ON ca.cs_warehouse_sk = wa.ws_warehouse_sk
       AND ca.cs_item_sk = wa.ws_item_sk
)
SELECT
    w.w_warehouse_name,
    i.i_category,
    i.i_item_desc,
    regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS numeric_code,
    CASE
        WHEN regexp_like(i.i_item_desc, '^.*[A-Z]{2}.*$') THEN 'Alpha'
        ELSE 'Other'
    END AS desc_type,
    c.total_sales,
    c.total_profit
FROM combined c
JOIN warehouse w ON c.warehouse_sk = w.w_warehouse_sk
JOIN item i ON c.item_sk = i.i_item_sk
WHERE w.w_city LIKE '%York%'
  AND (i.i_item_desc LIKE '%BRIGHT%' OR regexp_like(i.i_item_desc, '.*\\bPRO\\b.*'))
ORDER BY c.total_sales DESC
LIMIT 100
