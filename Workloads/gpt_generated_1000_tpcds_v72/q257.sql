WITH active_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_category,
           i.i_manager_id
    FROM   item i
    WHERE  i.i_manager_id IN (21, 63, 98)
)
SELECT  manager_id,
        category,
        sales_type,
        total_sales,
        avg_unit_price,
        grouping_id
FROM (
    -- Store channel aggregation
    SELECT  ai.i_manager_id                     AS manager_id,
            ai.i_category                       AS category,
            'store'                             AS sales_type,
            SUM(ss.ss_ext_sales_price)          AS total_sales,
            AVG(ss.ss_sales_price)              AS avg_unit_price,
            GROUPING(ai.i_manager_id, ai.i_category) AS grouping_id
    FROM    store_sales ss
    JOIN    active_items ai
            ON ss.ss_item_sk = ai.i_item_sk
    JOIN    customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE   NOT EXISTS (
                SELECT 1
                FROM   inventory inv
                WHERE  inv.inv_item_sk = ai.i_item_sk
                  AND  inv.inv_quantity_on_hand > 0
            )
    GROUP BY GROUPING SETS (
                (ai.i_manager_id, ai.i_category),
                (ai.i_manager_id),
                (ai.i_category),
                ()
            )
    UNION ALL
    -- Web channel aggregation
    SELECT  ai.i_manager_id                     AS manager_id,
            ai.i_category                       AS category,
            'web'                               AS sales_type,
            SUM(ws.ws_ext_sales_price)          AS total_sales,
            AVG(ws.ws_sales_price)              AS avg_unit_price,
            GROUPING(ai.i_manager_id, ai.i_category) AS grouping_id
    FROM    web_sales ws
    JOIN    active_items ai
            ON ws.ws_item_sk = ai.i_item_sk
    JOIN    customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE   EXISTS (
                SELECT 1
                FROM   call_center cc
                WHERE  cc.cc_state = 'CA'
            )
      AND NOT EXISTS (
                SELECT 1
                FROM   inventory inv
                WHERE  inv.inv_item_sk = ai.i_item_sk
                  AND  inv.inv_quantity_on_hand > 0
            )
    GROUP BY GROUPING SETS (
                (ai.i_manager_id, ai.i_category),
                (ai.i_manager_id),
                (ai.i_category),
                ()
            )
) AS combined
ORDER BY total_sales DESC
LIMIT 100
