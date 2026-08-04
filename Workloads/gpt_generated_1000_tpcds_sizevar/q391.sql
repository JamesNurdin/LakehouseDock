WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_category,
           i_current_price
    FROM   item
    WHERE  i_current_price > 20
)
SELECT combined.item_id,
       combined.channel,
       combined.total_quantity,
       combined.total_amount,
       combined.amount_level
FROM (
    SELECT i.i_item_id                              AS item_id,
           'catalog'                                 AS channel,
           SUM(cr.cr_return_quantity)                AS total_quantity,
           SUM(cr.cr_return_amount)                  AS total_amount,
           CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'HIGH' ELSE 'LOW' END AS amount_level
    FROM   catalog_returns cr
           JOIN filtered_items i
             ON cr.cr_item_sk = i.i_item_sk
           JOIN catalog_page cp
             ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE  cp.cp_department = 'DEPARTMENT'
    GROUP BY i.i_item_id

    UNION

    SELECT i.i_item_id                              AS item_id,
           'web'                                     AS channel,
           SUM(ws.ws_quantity)                       AS total_quantity,
           SUM(ws.ws_ext_sales_price)                AS total_amount,
           CASE WHEN SUM(ws.ws_ext_sales_price) > 500 THEN 'HIGH' ELSE 'LOW' END AS amount_level
    FROM   web_sales ws
           JOIN filtered_items i
             ON ws.ws_item_sk = i.i_item_sk
           JOIN web_site wsite
             ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE  wsite.web_country = 'United States'
    GROUP BY i.i_item_id
) AS combined
WHERE combined.item_id NOT IN (
    SELECT i2.i_item_id
    FROM   catalog_returns cr2
           JOIN item i2
             ON cr2.cr_item_sk = i2.i_item_sk
    WHERE  cr2.cr_return_amount > 1000
)
LIMIT 100
