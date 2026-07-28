WITH agg AS (
    SELECT
        store.s_division_name AS division_name,
        customer.c_birth_month AS birth_month,
        SUM(store_returns.sr_net_loss) AS total_net_loss,
        AVG(store_returns.sr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM store
    LEFT JOIN store_returns
        ON store.s_store_sk = store_returns.sr_store_sk
    LEFT JOIN customer
        ON store_returns.sr_customer_sk = customer.c_customer_sk
    WHERE
        store.s_state = 'CA'                         -- filter 1: stores in California
        AND customer.c_birth_month IN (5, 10, 11)     -- filter 2: customers born in May, Oct, Nov
        AND store_returns.sr_fee > 20                -- filter 3: fees greater than 20
    GROUP BY ROLLUP (store.s_division_name, customer.c_birth_month)
)
SELECT
    division_name,
    birth_month,
    total_net_loss,
    avg_fee,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY division_name ORDER BY total_net_loss DESC NULLS LAST) AS division_rank
FROM agg
ORDER BY division_name, birth_month
LIMIT 100
