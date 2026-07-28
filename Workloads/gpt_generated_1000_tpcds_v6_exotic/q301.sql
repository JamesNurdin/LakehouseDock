WITH manager_info AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_manager,
        regexp_extract(s.s_manager, '(\\w+) (\\w+)', 1) AS first_name,
        regexp_extract(s.s_manager, '(\\w+) (\\w+)', 2) AS last_name,
        s.s_city,
        s.s_state,
        s.s_store_sk
    FROM store s
    WHERE regexp_like(s.s_manager, '^J.*')
      AND s.s_city LIKE '%York%'
      AND substr(s.s_state, 1, 2) = 'NY'
),
filtered_returns AS (
    SELECT
        sr_store_sk,
        sr_customer_sk,
        sr_refunded_cash,
        sr_return_amt
    FROM store_returns
    WHERE sr_refunded_cash > 10
)
SELECT
    mi.s_store_id,
    mi.s_store_name,
    mi.s_manager,
    mi.first_name,
    mi.last_name,
    COUNT(DISTINCT fr.sr_customer_sk) AS distinct_customers,
    SUM(fr.sr_refunded_cash) AS total_refunded_cash,
    SUM(fr.sr_return_amt) AS total_return_amount
FROM manager_info mi
JOIN filtered_returns fr
    ON fr.sr_store_sk = mi.s_store_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = mi.s_store_sk
          AND sr2.sr_fee > 200
    )
GROUP BY
    mi.s_store_id,
    mi.s_store_name,
    mi.s_manager,
    mi.first_name,
    mi.last_name
ORDER BY total_refunded_cash DESC
LIMIT 100
