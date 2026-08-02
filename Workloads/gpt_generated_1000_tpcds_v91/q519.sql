WITH returns_combined AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        sr.sr_return_amt,
        sr.sr_fee,
        d.d_following_holiday
    FROM store s
    FULL OUTER JOIN store_returns sr
        ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_following_holiday = 'Y'
      AND s.s_state = 'CA'
      AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND sr2.sr_fee > 50
        )
    UNION ALL
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        sr.sr_return_amt,
        sr.sr_fee,
        d.d_following_holiday
    FROM store s
    FULL OUTER JOIN store_returns sr
        ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_following_holiday = 'N'
      AND s.s_state = 'TX'
)
SELECT
    COALESCE(s_store_id, 'ALL') AS store_id,
    COALESCE(d_year, -1) AS year,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_fee) AS total_fee,
    COUNT(*) AS return_count,
    (SELECT MAX(d_year) FROM date_dim) AS max_year_in_data,
    CASE
        WHEN GROUPING(s_store_id) = 1 AND GROUPING(d_year) = 0 THEN 'Year Subtotal'
        WHEN GROUPING(s_store_id) = 0 AND GROUPING(d_year) = 1 THEN 'Store Subtotal'
        WHEN GROUPING(s_store_id) = 1 AND GROUPING(d_year) = 1 THEN 'Grand Total'
        ELSE 'Detail'
    END AS row_type
FROM returns_combined
GROUP BY GROUPING SETS (
    (s_store_id, d_year),
    (s_store_id),
    (d_year),
    ()
)
ORDER BY store_id, year
LIMIT 100
