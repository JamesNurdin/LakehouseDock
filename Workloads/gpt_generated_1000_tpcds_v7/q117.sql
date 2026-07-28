WITH catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        i.i_current_price AS current_price,
        cr.cr_return_amount AS return_amount,
        r.r_reason_desc AS reason,
        'Catalog' AS source
    FROM catalog_returns cr
    INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id = 10
),
store_ret AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        i.i_current_price AS current_price,
        sr.sr_return_amt AS return_amount,
        r.r_reason_desc AS reason,
        'Store' AS source
    FROM store_returns sr
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN item i ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND ca.ca_country = 'United States'
      AND ca.ca_location_type = 'single family'
)
SELECT *
FROM catalog_ret
UNION ALL
SELECT *
FROM store_ret
LIMIT 100
