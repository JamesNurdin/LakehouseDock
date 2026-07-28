WITH tx_returns AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_county,
        sr.sr_store_credit,
        sr.sr_return_ship_cost,
        sr.sr_reversed_charge,
        CASE 
            WHEN sr.sr_store_credit > 500 THEN 'HIGH'
            WHEN sr.sr_store_credit > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS credit_category,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY sr.sr_store_credit DESC) AS rank_state,
        NULL AS rank_county
    FROM tpcds.store_returns sr
    JOIN tpcds.customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'TX'
      AND ca.ca_county = 'Madison County'
      AND sr.sr_store_credit > 50
      AND sr.sr_return_ship_cost < 50
      AND sr.sr_reversed_charge BETWEEN 10 AND 200
      AND sr.sr_return_quantity >= 1
      AND sr.sr_return_amt > 0
),
ca_returns AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_county,
        sr.sr_store_credit,
        sr.sr_return_ship_cost,
        sr.sr_reversed_charge,
        CASE 
            WHEN sr.sr_store_credit > 500 THEN 'HIGH'
            WHEN sr.sr_store_credit > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS credit_category,
        NULL AS rank_state,
        DENSE_RANK() OVER (PARTITION BY ca.ca_county ORDER BY sr.sr_reversed_charge DESC) AS rank_county
    FROM tpcds.store_returns sr
    JOIN tpcds.customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_county = 'Lipscomb County'
      AND sr.sr_store_credit BETWEEN 0 AND 20
      AND sr.sr_return_ship_cost > 10
      AND sr.sr_reversed_charge > 100
      AND sr.sr_return_quantity >= 2
      AND sr.sr_return_amt > 100
)
SELECT * FROM tx_returns
UNION ALL
SELECT * FROM ca_returns
ORDER BY rank_state ASC NULLS LAST, rank_county ASC NULLS LAST
LIMIT 100
