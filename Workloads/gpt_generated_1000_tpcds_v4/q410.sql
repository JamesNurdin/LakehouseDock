WITH filtered_warehouses AS (
    SELECT w_warehouse_sk,
           w_warehouse_id,
           w_city
    FROM   warehouse
    WHERE  w_state IN ('CA', 'TX', 'NY')
)
SELECT DISTINCT
       warehouse_id,
       city,
       total_return_amount,
       total_sales,
       return_cnt,
       sales_cnt
FROM (
    SELECT wf.w_warehouse_id AS warehouse_id,
           wf.w_city        AS city,
           SUM(cr.cr_return_amount)               AS total_return_amount,
           CAST(NULL AS decimal(7,2))              AS total_sales,
           COUNT(*)                                AS return_cnt,
           CAST(NULL AS bigint)                    AS sales_cnt
    FROM   catalog_returns cr
    JOIN   filtered_warehouses wf
           ON cr.cr_warehouse_sk = wf.w_warehouse_sk
    WHERE  cr.cr_return_amount > 100.00
    GROUP BY wf.w_warehouse_id, wf.w_city

    UNION ALL

    SELECT wf.w_warehouse_id AS warehouse_id,
           wf.w_city        AS city,
           CAST(NULL AS decimal(7,2))              AS total_return_amount,
           SUM(ws.ws_ext_sales_price)              AS total_sales,
           CAST(NULL AS bigint)                    AS return_cnt,
           COUNT(*)                                AS sales_cnt
    FROM   web_sales ws
    JOIN   filtered_warehouses wf
           ON ws.ws_warehouse_sk = wf.w_warehouse_sk
    WHERE  ws.ws_ext_sales_price > 5000.00
    GROUP BY wf.w_warehouse_id, wf.w_city
) AS combined
ORDER BY warehouse_id
LIMIT 100
