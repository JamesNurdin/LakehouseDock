WITH store_ret AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        SUM(sr.sr_return_amt) AS total_return,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND ca.ca_city LIKE 'San%'
    GROUP BY c.c_customer_id, ca.ca_state
    HAVING SUM(sr.sr_return_amt) > 1000
),
web_ret AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        SUM(wr.wr_return_amt) AS total_return,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(c.c_email_address, '^.+@gmail\\.com$')
      AND ca.ca_city LIKE '%York%'
    GROUP BY c.c_customer_id, ca.ca_state
    HAVING SUM(wr.wr_return_amt) > 500
),
union_ret AS (
    SELECT c_customer_id, ca_state, total_return, return_cnt FROM store_ret
    UNION
    SELECT c_customer_id, ca_state, total_return, return_cnt FROM web_ret
),
high_income_cust AS (
    SELECT
        c.c_customer_id,
        ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 150000
)
SELECT
    fin.c_customer_id,
    fin.ca_state,
    fin.total_return,
    fin.return_cnt,
    regexp_extract(c.c_email_address, '([^@]+)@', 1) AS email_local,
    CONCAT(fin.ca_state, '-', CAST(fin.total_return AS VARCHAR)) AS state_return_key
FROM (
    SELECT u.c_customer_id, u.ca_state, u.total_return, u.return_cnt
    FROM union_ret u
    EXCEPT
    SELECT h.c_customer_id, h.ca_state, u.total_return, u.return_cnt
    FROM high_income_cust h
    JOIN union_ret u ON h.c_customer_id = u.c_customer_id AND h.ca_state = u.ca_state
) fin
JOIN customer c ON c.c_customer_id = fin.c_customer_id
ORDER BY fin.total_return DESC
LIMIT 100
