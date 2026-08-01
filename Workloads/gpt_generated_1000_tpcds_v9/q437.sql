WITH catalog_ret AS (
    SELECT
        i.i_item_id AS item_id,
        'Catalog' AS return_channel,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Normal' END AS return_flag
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id
),
web_ret AS (
    SELECT
        i.i_item_id AS item_id,
        'Web' AS return_channel,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'High' ELSE 'Normal' END AS return_flag
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id
)
SELECT DISTINCT
    item_id,
    return_channel,
    total_return_amount,
    total_return_quantity,
    return_flag
FROM (
    SELECT
        item_id,
        return_channel,
        total_return_amount,
        total_return_quantity,
        return_flag
    FROM catalog_ret
    UNION ALL
    SELECT
        item_id,
        return_channel,
        total_return_amount,
        total_return_quantity,
        return_flag
    FROM web_ret
) combined
ORDER BY total_return_amount DESC
LIMIT 100
