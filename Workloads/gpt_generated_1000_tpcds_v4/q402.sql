WITH ws_agg AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_paid_inc_tax) AS avg_paid_inc_tax
    FROM
        tpcds.web_sales
    WHERE
        ws_net_paid_inc_tax > 100
        AND ws_sold_time_sk BETWEEN 30000 AND 80000
        AND ws_quantity > 0
    GROUP BY
        ws_item_sk
)
SELECT
    i.i_brand,
    i.i_category,
    SUM(ws_agg.total_sales) AS brand_category_sales,
    AVG(ws_agg.avg_paid_inc_tax) AS avg_paid_per_item,
    SUM(ws_agg.total_quantity) AS total_quantity_sold
FROM
    ws_agg
JOIN
    tpcds.item AS i
    ON ws_agg.ws_item_sk = i.i_item_sk
WHERE
    i.i_class_id IN (1, 5, 13)
    AND i.i_manufact_id = 260
    AND i.i_color IS NOT NULL
GROUP BY
    i.i_brand,
    i.i_category
HAVING
    SUM(ws_agg.total_sales) > 1000
ORDER BY
    brand_category_sales DESC
LIMIT 100
