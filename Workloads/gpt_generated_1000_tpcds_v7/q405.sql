WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_store_credit,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_ticket_number,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        ca.ca_state,
        ca.ca_gmt_offset
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count BETWEEN 0 AND 3
      AND sr.sr_store_credit > 20
      AND ca.ca_gmt_offset BETWEEN -5 AND 5
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND sr.sr_return_amt > 0
)
SELECT
    store_sk,
    state,
    buy_potential,
    total_return_amt,
    total_quantity,
    RANK() OVER (ORDER BY total_return_amt DESC) AS store_return_rank,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_return_amt DESC) AS rn_state
FROM (
    SELECT
        sr_store_sk AS store_sk,
        ca_state AS state,
        hd_buy_potential AS buy_potential,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_quantity
    FROM filtered_returns
    GROUP BY
        sr_store_sk,
        ca_state,
        hd_buy_potential
) agg
ORDER BY total_return_amt DESC
LIMIT 100
