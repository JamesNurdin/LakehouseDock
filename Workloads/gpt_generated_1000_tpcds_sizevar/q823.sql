WITH sampled_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        ca.ca_county,
        ARRAY[cr.cr_return_amount, cr.cr_fee] AS amount_fee_arr
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county IN ('Madison County', 'Richland County')
),
second_sampled_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        ca.ca_county,
        ARRAY[cr.cr_return_amount, cr.cr_fee] AS amount_fee_arr
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county = 'Mifflin County'
),
small_dim AS (
    SELECT 'refunded' AS addr_role
    UNION ALL SELECT 'returning'
)
SELECT
    sr.cr_returned_date_sk,
    sr.ca_county,
    v.amt_value,
    v.pos,
    sd.addr_role
FROM sampled_returns sr
CROSS JOIN UNNEST(sr.amount_fee_arr) WITH ORDINALITY AS v (amt_value, pos)
CROSS JOIN small_dim sd
WHERE sd.addr_role = 'refunded'
UNION ALL
SELECT
    sr2.cr_returned_date_sk,
    sr2.ca_county,
    v2.amt_value,
    v2.pos,
    sd2.addr_role
FROM second_sampled_returns sr2
CROSS JOIN UNNEST(sr2.amount_fee_arr) WITH ORDINALITY AS v2 (amt_value, pos)
CROSS JOIN small_dim sd2
WHERE sd2.addr_role = 'returning'
LIMIT 100
