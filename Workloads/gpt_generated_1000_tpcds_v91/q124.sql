WITH item_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        array[
            CAST(COALESCE(inv.inv_quantity_on_hand, 0) AS decimal(7,2)),
            i.i_current_price
        ] AS metrics_array
    FROM item i
    FULL OUTER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
)
SELECT source, key, metric_name, metric_value
FROM (
    SELECT
        'sales' AS source,
        CONCAT('hour_', CAST(td.t_hour AS varchar)) AS key,
        'sales_amount' AS metric_name,
        SUM(ss.ss_ext_sales_price) AS metric_value
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour

    UNION ALL

    SELECT
        'inventory' AS source,
        CAST(COALESCE(ii.inv_warehouse_sk, -1) AS varchar) AS key,
        l.metric_name,
        SUM(l.metric_value) AS metric_value
    FROM item_inventory ii
    CROSS JOIN LATERAL (
        SELECT
            CASE idx WHEN 1 THEN 'quantity_on_hand' ELSE 'current_price' END AS metric_name,
            val AS metric_value
        FROM UNNEST(ii.metrics_array) WITH ORDINALITY AS u(val, idx)
    ) AS l
    GROUP BY ii.inv_warehouse_sk, l.metric_name
) AS combined
ORDER BY source, key, metric_name
LIMIT 100
