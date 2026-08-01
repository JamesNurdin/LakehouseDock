WITH catalog_agg AS (
    SELECT
        ca.ca_state AS state,
        sm_l.sm_carrier AS carrier,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE
            WHEN sm_l.sm_carrier IN ('ORIENTAL', 'MSC') THEN 'Domestic'
            ELSE 'International'
        END AS carrier_category,
        REGEXP_EXTRACT(sm_l.sm_contract, '(\\d+)', 1) AS contract_num
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT sm.sm_carrier, sm.sm_contract
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    ) AS sm_l
    WHERE REGEXP_LIKE(ca.ca_zip, '^1[0-9]{4}$')
      AND ca.ca_city LIKE '%ville%'
    GROUP BY ca.ca_state, sm_l.sm_carrier, sm_l.sm_contract
),
store_agg AS (
    SELECT
        ca.ca_state AS state,
        'N/A' AS carrier,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_orders,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE
            WHEN ca.ca_gmt_offset >= 0 THEN 'East'
            ELSE 'West'
        END AS carrier_category,
        NULL AS contract_num
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_location_type = 'condo'
      AND SUBSTRING(ca.ca_street_number FROM 1 FOR 1) = '9'
    GROUP BY ca.ca_state, ca.ca_gmt_offset
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT
    c.state,
    c.carrier,
    c.distinct_orders,
    c.total_net_loss,
    c.carrier_category,
    c.contract_num,
    CASE
        WHEN c.total_net_loss > (SELECT AVG(cr.cr_net_loss) FROM catalog_returns cr) THEN 'Above Avg Catalog'
        ELSE 'Below Avg Catalog'
    END AS loss_vs_catalog_avg,
    (SELECT COUNT(DISTINCT ca2.ca_address_sk) FROM customer_address ca2 WHERE ca2.ca_state = c.state) AS distinct_addresses_in_state
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca3
    WHERE ca3.ca_state = c.state
      AND ca3.ca_zip LIKE '9%'
)
ORDER BY c.state, c.total_net_loss DESC
LIMIT 100
