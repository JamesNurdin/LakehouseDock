/*
  Goal: Rank stores by total return amount, comparing Riverside stores (division 1) against other stores with high return amounts, using a UNION ALL of two filtered sets.
*/
WITH store_return_agg AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_id AS store_id,
        s.s_city AS city,
        s.s_division_id AS division_id,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_quantity,
        COUNT(*) AS txn_count
    FROM store AS s
    JOIN store_returns AS sr
        ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_id, s.s_city, s.s_division_id
)
SELECT
    store_id,
    city,
    total_return_amt,
    txn_count,
    rank() OVER (PARTITION BY city ORDER BY total_return_amt DESC) AS city_return_rank
FROM (
    SELECT
        store_id,
        city,
        total_return_amt,
        txn_count
    FROM store_return_agg
    WHERE city = 'Riverside' AND division_id = 1

    UNION ALL

    SELECT
        store_id,
        city,
        total_return_amt,
        txn_count
    FROM store_return_agg
    WHERE city IN ('Stringtown', 'Fairview')
      AND total_return_amt > 1000
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
