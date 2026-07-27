WITH sales AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        concat(i.i_brand, '-', i.i_item_id) AS brand_item,
        regexp_extract(i.i_item_id, '\\d+') AS numeric_part,
        'sales' AS metric_type,
        SUM(ws.ws_ext_sales_price) AS amount,
        CASE WHEN SUM(ws.ws_quantity) > 100 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        regexp_like(i.i_item_desc, '[0-9]{3}')
        AND wp.wp_url LIKE '%example.com%'
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        i.i_brand
),
returns AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        concat(i.i_brand, '-', i.i_item_id) AS brand_item,
        regexp_extract(i.i_item_id, '\\d+') AS numeric_part,
        'returns' AS metric_type,
        -SUM(sr.sr_net_loss) AS amount,
        CASE WHEN SUM(sr.sr_return_quantity) > 50 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        i.i_brand = 'BrandX'
        AND ca.ca_state LIKE 'C%'
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        i.i_brand
)
SELECT
    item_id,
    item_desc,
    brand_item,
    numeric_part,
    metric_type,
    amount,
    volume_category
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) AS combined
ORDER BY amount DESC
LIMIT 100
