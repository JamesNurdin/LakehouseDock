WITH item_inventory AS (
    SELECT DISTINCT
        i.i_item_sk,
        i.i_item_id,
        inv.inv_quantity_on_hand
    FROM item i
    FULL OUTER JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
        AND inv.inv_date_sk = (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2001
            LIMIT 1
        )
)
SELECT year,
       item_id,
       metric,
       metric_value
FROM (
    SELECT
        d.d_year AS year,
        i.i_item_id AS item_id,
        'sales' AS metric,
        SUM(ws.ws_ext_sales_price) AS metric_value
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_coupon_amt > (
            SELECT AVG(ws2.ws_coupon_amt)
            FROM web_sales ws2
          )
      AND d.d_year = 2001
    GROUP BY d.d_year, i.i_item_id

    UNION

    SELECT
        d.d_year AS year,
        ii.i_item_id AS item_id,
        'returns' AS metric,
        SUM(cr.cr_return_amount) AS metric_value
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item_inventory ii
        ON cr.cr_item_sk = ii.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, ii.i_item_id
) AS combined
ORDER BY year, item_id, metric
LIMIT 100
