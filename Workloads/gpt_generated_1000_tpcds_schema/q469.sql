WITH
    sampled_store_returns AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    address_expanded AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_addr_sk,
            ca.ca_address_id,
            ARRAY[ca.ca_street_number, ca.ca_street_type] AS addr_parts
        FROM sampled_store_returns sr
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
    ),
    unnested_address AS (
        SELECT
            sr_ticket_number,
            sr_addr_sk,
            ca_address_id,
            part AS address_component
        FROM address_expanded
        CROSS JOIN UNNEST(addr_parts) AS t(part)
    ),
    full_joined AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_ticket_number,
            ca.ca_address_id,
            sr.sr_return_amt,
            ca.ca_city
        FROM store_returns sr
        FULL OUTER JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
    ),
    right_joined AS (
        SELECT
            d.d_date,
            sr.sr_return_amt
        FROM store_returns sr
        RIGHT OUTER JOIN date_dim d
            ON sr.sr_returned_date_sk = d.d_date_sk
    ),
    key_set_excluding AS (
        SELECT c.c_customer_sk
        FROM customer c
        EXCEPT
        SELECT sr.sr_customer_sk
        FROM store_returns sr
    )
SELECT src, key, value
FROM (
    SELECT
        'UnnestedAddr' AS src,
        CAST(ua.sr_ticket_number AS VARCHAR) AS key,
        ua.address_component AS value
    FROM unnested_address ua

    UNION ALL

    SELECT
        'FullJoin' AS src,
        CAST(fj.sr_ticket_number AS VARCHAR) AS key,
        CONCAT('Amt:', CAST(fj.sr_return_amt AS VARCHAR), ', City:', COALESCE(fj.ca_city, 'NULL')) AS value
    FROM full_joined fj
    WHERE fj.sr_ticket_number IS NOT NULL OR fj.ca_city IS NOT NULL

    UNION ALL

    SELECT
        'RightJoin' AS src,
        CAST(rj.d_date AS VARCHAR) AS key,
        CAST(rj.sr_return_amt AS VARCHAR) AS value
    FROM right_joined rj
    WHERE rj.sr_return_amt IS NOT NULL

    UNION ALL

    SELECT
        'KeyExcept' AS src,
        CAST(kse.c_customer_sk AS VARCHAR) AS key,
        NULL AS value
    FROM key_set_excluding kse
) combined
ORDER BY src, key
LIMIT 100
