WITH ws_sample AS (
    SELECT *
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
),

bill_match AS (
    SELECT DISTINCT ca.ca_address_sk AS address_sk
    FROM ws_sample ws
    JOIN tpcds.customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_street_name, '^Spring')
),

ship_match AS (
    SELECT DISTINCT ca.ca_address_sk AS address_sk
    FROM ws_sample ws
    JOIN tpcds.customer_address ca
      ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE '%County'
),

intersected_addrs AS (
    SELECT address_sk FROM bill_match
    INTERSECT
    SELECT address_sk FROM ship_match
),

agg_sales AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        regexp_extract(ca.ca_street_name, '(\\w+)', 1) AS street_prefix,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        CASE
            WHEN ca.ca_state = 'CA' THEN 'West'
            WHEN ca.ca_state IN ('NY','NJ','CT') THEN 'East'
            ELSE 'Other'
        END AS region_category
    FROM ws_sample ws
    JOIN tpcds.customer_address ca
      ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN intersected_addrs ia
      ON ca.ca_address_sk = ia.address_sk
    GROUP BY
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        regexp_extract(ca.ca_street_name, '(\\w+)', 1),
        CASE
            WHEN ca.ca_state = 'CA' THEN 'West'
            WHEN ca.ca_state IN ('NY','NJ','CT') THEN 'East'
            ELSE 'Other'
        END
)
SELECT DISTINCT
    ca_address_sk,
    ca_city,
    ca_state,
    street_prefix,
    total_net_paid,
    distinct_orders,
    region_category
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 100
