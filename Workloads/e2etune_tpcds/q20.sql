WITH agg AS (
    SELECT 
        ca.ca_state AS state,
        ca.ca_zip AS zip,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_quantity,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 100
      AND ca.ca_state IN ('TN', 'GA')
      AND hd.hd_vehicle_count >= 2
    GROUP BY ca.ca_state, ca.ca_zip
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    state,
    zip,
    total_return_amount,
    total_quantity,
    avg_return_amt,
    distinct_customers,
    avg_vehicle_count,
    RANK() OVER (PARTITION BY state ORDER BY total_return_amount DESC) AS zip_rank
FROM agg
ORDER BY state, zip_rank
