WITH item_sales AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_net_paid_inc_ship_tax) AS web_sales,
        SUM(cs.cs_net_paid_inc_ship_tax) AS catalog_sales,
        CASE
            WHEN SUM(ws.ws_net_paid_inc_ship_tax) >= COALESCE(SUM(cs.cs_net_paid_inc_ship_tax), 0) THEN 'WEB'
            ELSE 'CATALOG'
        END AS top_source
    FROM item i
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
)

SELECT
    us.i_item_id,
    us.web_sales,
    us.catalog_sales,
    us.top_source
FROM (
    SELECT i_item_id, web_sales, catalog_sales, top_source
    FROM item_sales
    WHERE web_sales > 4000
    UNION
    SELECT i_item_id, web_sales, catalog_sales, top_source
    FROM item_sales
    WHERE catalog_sales > 4000
) AS us
WHERE us.i_item_id IN (
    SELECT i1.i_item_id
    FROM store_returns sr
    JOIN item i1
        ON i1.i_item_sk = sr.sr_item_sk
    INTERSECT
    SELECT i2.i_item_id
    FROM web_returns wr
    JOIN item i2
        ON i2.i_item_sk = wr.wr_item_sk
)
AND NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
        ON i.i_item_id = us.i_item_id
    WHERE cr.cr_item_sk = i.i_item_sk
      AND cs.cs_item_sk = i.i_item_sk
)
ORDER BY us.web_sales DESC
LIMIT 100
