SELECT
    item_id,
    product_name,
    full_desc,
    total_sales,
    total_returns,
    reason_flag,
    channel,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS rank_in_channel
FROM (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        CONCAT(i.i_product_name, ' - ', i.i_brand) AS full_desc,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_quantity) AS total_returns,
        MAX(CASE WHEN r.r_reason_desc LIKE '%size%' THEN 1 ELSE 0 END) AS reason_flag,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{3}')
    GROUP BY i.i_item_id, i.i_product_name, i.i_brand

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        CONCAT(i.i_product_name, ' - ', i.i_brand) AS full_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_quantity) AS total_returns,
        MAX(CASE WHEN r.r_reason_desc LIKE '%fit%' THEN 1 ELSE 0 END) AS reason_flag,
        'Web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{2}')
    GROUP BY i.i_item_id, i.i_product_name, i.i_brand
) AS combined
ORDER BY total_sales DESC
LIMIT 100
