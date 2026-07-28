WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_return_quantity) AS total_qty,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                     -- predicate 1
      AND sr.sr_return_quantity > 0                         -- predicate 2
      AND sr.sr_return_amt_inc_tax > 0                      -- predicate 3
      AND sr.sr_return_tax < 200                            -- predicate 4
      AND sr.sr_fee BETWEEN 0 AND 100                       -- predicate 5
    GROUP BY sr.sr_store_sk, sr.sr_customer_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_id,
    c.c_customer_id,
    a.d_year,
    a.d_month_seq,
    a.total_return_inc_tax,
    a.total_qty,
    CASE
        WHEN a.total_return_inc_tax > 5000 THEN 'High'
        WHEN a.total_return_inc_tax > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level,                                       -- CASE expression
    w.web_name,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_inc_tax DESC) AS rn_year,
    RANK()       OVER (PARTITION BY a.d_year ORDER BY a.total_return_inc_tax DESC) AS rank_year,
    (
        SELECT MAX(d2.d_date)
        FROM date_dim d2
        JOIN store_returns sr2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE sr2.sr_store_sk = s.s_store_sk
    ) AS latest_return_date                                      -- scalar subquery
FROM sr_agg a
JOIN store s
  ON a.sr_store_sk = s.s_store_sk                                   -- join rule 3
JOIN customer c
  ON a.sr_customer_sk = c.c_customer_sk                               -- join rule 2
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk                    -- join rule 4
JOIN web_site w
  ON w.web_open_date_sk = d_store_closed.d_date_sk                    -- join rule 5
WHERE s.s_state = 'TX'                                                -- predicate 6
  AND c.c_preferred_cust_flag = 'Y'                                   -- predicate 7
  AND w.web_class = 'A'                                               -- predicate 8
  AND d_store_closed.d_year = a.d_year                                 -- predicate 9
  AND w.web_tax_percentage < 10                                      -- predicate 10
  AND s.s_tax_percentage >= 5                                         -- predicate 11
ORDER BY a.d_year DESC, rank_year
LIMIT 100
