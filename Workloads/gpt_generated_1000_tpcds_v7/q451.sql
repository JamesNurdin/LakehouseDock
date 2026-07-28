/* goal: Combine sales and returns events for the year 2000, showing the event date, type (sale or return), monetary amount, item id, and warehouse name, ordered chronologically */
WITH sales AS (
    SELECT
        d.d_date AS event_date,
        CAST('sale' AS varchar) AS event_type,
        cs.cs_net_paid AS amount,
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
),
returns AS (
    SELECT
        d.d_date AS event_date,
        CAST('return' AS varchar) AS event_type,
        cr.cr_return_amount AS amount,
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
)
SELECT * FROM sales
UNION ALL
SELECT * FROM returns
ORDER BY event_date, event_type
LIMIT 100
