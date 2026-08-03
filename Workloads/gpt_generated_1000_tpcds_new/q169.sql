WITH catalog_agg AS (
    SELECT
        ca.ca_county,
        ca.ca_location_type,
        regexp_extract(ca.ca_address_id, '(A{3,})', 1) AS address_pattern,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amt_inc_tax) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_address_id, '^A{7,}E')
      AND ca.ca_location_type LIKE '%family%'
    GROUP BY ca.ca_county,
             ca.ca_location_type,
             regexp_extract(ca.ca_address_id, '(A{3,})', 1)
),
store_agg AS (
    SELECT
        ca.ca_county,
        ca.ca_location_type,
        regexp_extract(ca.ca_address_id, '(A{3,})', 1) AS address_pattern,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amount
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county LIKE '%County'
      AND ca.ca_address_id LIKE '%A%'
    GROUP BY ca.ca_county,
             ca.ca_location_type,
             regexp_extract(ca.ca_address_id, '(A{3,})', 1)
)
SELECT *
FROM catalog_agg
UNION DISTINCT
SELECT *
FROM store_agg
ORDER BY total_net_loss DESC
LIMIT 100
