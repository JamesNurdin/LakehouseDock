WITH sales AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_state AS state,
        'sales' AS transaction_type,
        SUM(ss.ss_net_paid) AS total_amount
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-06-30'
      AND ca.ca_gmt_offset = -6.00
      AND ss.ss_ext_list_price > 5000
    GROUP BY s.s_store_id, s.s_state
),
returns AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_state AS state,
        'returns' AS transaction_type,
        SUM(sr.sr_refunded_cash) AS total_amount
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE s.s_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-06-30'
      AND ca.ca_gmt_offset = -6.00
      AND sr.sr_refunded_cash > 500
    GROUP BY s.s_store_id, s.s_state
),
combined AS (
    SELECT store_id, state, transaction_type, total_amount FROM sales
    UNION ALL
    SELECT store_id, state, transaction_type, total_amount FROM returns
)
SELECT
    transaction_type,
    COALESCE(store_id, 'ALL') AS store_id,
    COALESCE(state, 'ALL') AS state,
    SUM(total_amount) AS total_amount
FROM combined
GROUP BY GROUPING SETS (
    (transaction_type, store_id, state),
    (transaction_type, store_id),
    (transaction_type, state),
    (transaction_type)
)
ORDER BY transaction_type, store_id, state
LIMIT 100
