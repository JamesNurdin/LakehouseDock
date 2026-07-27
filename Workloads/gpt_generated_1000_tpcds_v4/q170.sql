WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
        (SELECT AVG(ss2.ss_quantity) FROM store_sales ss2 WHERE ss2.ss_item_sk = i.i_item_sk) AS avg_quantity_per_item
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND i.i_units = 'Each'
    GROUP BY i.i_item_id, i.i_item_desc, i.i_item_sk
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
        (SELECT AVG(ws2.ws_quantity) FROM web_sales ws2 WHERE ws2.ws_item_sk = i.i_item_sk) AS avg_quantity_per_item
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE wsite.web_manager = 'John Thomas'
      AND i.i_units = 'Each'
    GROUP BY i.i_item_id, i.i_item_desc, i.i_item_sk
)
SELECT
    i_item_id,
    i_item_desc,
    total_net_paid,
    sales_category,
    avg_quantity_per_item
FROM store_agg
UNION ALL
SELECT
    i_item_id,
    i_item_desc,
    total_net_paid,
    sales_category,
    avg_quantity_per_item
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
