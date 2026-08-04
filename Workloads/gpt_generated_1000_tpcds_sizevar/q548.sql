WITH sampled_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_quantity > 20
      AND sr_item_sk IN (38281, 38618, 24289)
      AND sr_return_amt_inc_tax > 100
),
cust_filtered AS (
    SELECT *
    FROM customer
    WHERE c_current_hdemo_sk IN (2777, 7135, 1461)
      AND c_customer_id LIKE 'AAAAAAA%'
),
store_filtered AS (
    SELECT *
    FROM store
    WHERE s_county = 'Jackson County'
      AND s_street_name = 'Sycamore'
      AND s_rec_end_date = DATE '2001-03-12'
)
SELECT
    store_id,
    store_name,
    year,
    total_return_amt,
    avg_return_qty,
    distinct_tickets,
    min_return_amt,
    max_return_amt
FROM (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        y.year,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt
    FROM sampled_returns sr
    JOIN cust_filtered c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store_filtered s
        ON sr.sr_store_sk = s.s_store_sk
    CROSS JOIN (
        SELECT 2022 AS year UNION ALL SELECT 2023
    ) y
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_quantity > 30
    )
    GROUP BY s.s_store_id, s.s_store_name, y.year
    UNION
    SELECT
        s2.s_store_id AS store_id,
        s2.s_store_name AS store_name,
        y.year,
        SUM(sr2.sr_return_amt_inc_tax) AS total_return_amt,
        AVG(sr2.sr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT sr2.sr_ticket_number) AS distinct_tickets,
        MIN(sr2.sr_return_amt) AS min_return_amt,
        MAX(sr2.sr_return_amt) AS max_return_amt
    FROM sampled_returns sr2
    JOIN cust_filtered c2
        ON sr2.sr_customer_sk = c2.c_customer_sk
    JOIN store s2
        ON sr2.sr_store_sk = s2.s_store_sk
    CROSS JOIN (
        VALUES 2021, 2022
    ) AS y(year)
    WHERE s2.s_county = 'Walker County'
      AND s2.s_street_name = 'View Mill'
      AND sr2.sr_return_amt_inc_tax BETWEEN 50 AND 500
      AND c2.c_current_hdemo_sk = 89
    GROUP BY s2.s_store_id, s2.s_store_name, y.year
) agg
ORDER BY total_return_amt DESC
OFFSET 20
LIMIT 100
