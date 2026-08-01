WITH high_price_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > (SELECT AVG(i_current_price) FROM item)
)
SELECT
    customer_id,
    return_channel,
    latest_return_date,
    total_return_amount,
    total_quantity,
    loss_category
FROM (
    SELECT
        c.c_customer_id AS customer_id,
        'Catalog' AS return_channel,
        MAX(d.d_date) AS latest_return_date,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        CASE
            WHEN SUM(cr.cr_return_amt_inc_tax) > (SELECT AVG(cr2.cr_return_amt_inc_tax) FROM catalog_returns cr2) THEN 'High'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1
        FROM high_price_items hp
        WHERE hp.i_item_sk = cr.cr_item_sk
    )
      AND d.d_year = 2001
    GROUP BY c.c_customer_id
    UNION ALL
    SELECT
        c.c_customer_id AS customer_id,
        'Web' AS return_channel,
        MAX(d.d_date) AS latest_return_date,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_quantity,
        CASE
            WHEN SUM(wr.wr_return_amt_inc_tax) > (SELECT AVG(wr2.wr_return_amt_inc_tax) FROM web_returns wr2) THEN 'High'
            ELSE 'Low'
        END AS loss_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1
        FROM high_price_items hp
        WHERE hp.i_item_sk = wr.wr_item_sk
    )
      AND d.d_year = 2001
    GROUP BY c.c_customer_id
) AS combined_returns
ORDER BY total_return_amount DESC
LIMIT 100
