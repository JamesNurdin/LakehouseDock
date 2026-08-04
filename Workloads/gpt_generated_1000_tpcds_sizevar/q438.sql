WITH catalog_data AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        cr.cr_item_sk,
        i.i_product_name,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        sm.sm_carrier,
        amt_type,
        amt_value
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    CROSS JOIN UNNEST(ARRAY[ROW('return_amount', cr.cr_return_amount), ROW('return_tax', cr.cr_return_tax)]) AS t(amt_type, amt_value)
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_returned_date_sk = cr.cr_returned_date_sk
          AND wr.wr_item_sk = cr.cr_item_sk
    )
      AND d.d_year = 2002
      AND sm.sm_carrier = 'DHL'
),
web_data AS (
    SELECT
        wr.wr_returned_date_sk,
        d.d_year,
        wr.wr_item_sk,
        i.i_product_name,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        'WEB' AS source,
        amt_type,
        amt_value
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(ARRAY[ROW('return_amt', wr.wr_return_amt), ROW('return_tax', wr.wr_return_tax)]) AS t(amt_type, amt_value)
    WHERE d.d_year = 2002
      AND wr.wr_return_quantity > 0
),
full_joined AS (
    SELECT
        COALESCE(c.cr_returned_date_sk, w.wr_returned_date_sk) AS date_sk,
        COALESCE(c.d_year, w.d_year) AS year,
        COALESCE(c.cr_item_sk, w.wr_item_sk) AS item_sk,
        COALESCE(c.i_product_name, w.i_product_name) AS product_name,
        COALESCE(c.cr_return_quantity, w.wr_return_quantity) AS return_quantity,
        COALESCE(c.amt_type, w.amt_type) AS amount_type,
        COALESCE(c.amt_value, w.amt_value) AS amount_value,
        CASE
            WHEN c.cr_returned_date_sk IS NOT NULL AND w.wr_returned_date_sk IS NULL THEN 'CATALOG_ONLY'
            WHEN c.cr_returned_date_sk IS NULL AND w.wr_returned_date_sk IS NOT NULL THEN 'WEB_ONLY'
            ELSE 'BOTH'
        END AS source_flag
    FROM catalog_data c
    FULL OUTER JOIN web_data w
        ON c.cr_returned_date_sk = w.wr_returned_date_sk
       AND c.cr_item_sk = w.wr_item_sk
       AND c.amt_type = w.amt_type
)
SELECT
    date_sk,
    year,
    product_name,
    return_quantity,
    amount_type,
    amount_value,
    source_flag
FROM full_joined
WHERE source_flag <> 'BOTH'
UNION
SELECT
    date_sk,
    year,
    product_name,
    return_quantity,
    amount_type,
    amount_value,
    source_flag
FROM full_joined
WHERE source_flag = 'BOTH' AND amount_value > 1000
ORDER BY year DESC, amount_value DESC
LIMIT 100
