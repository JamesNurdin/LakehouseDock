WITH store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_fee) AS avg_fee,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    WHERE sr.sr_return_ship_cost > 100
      AND sr.sr_fee BETWEEN 20 AND 80
      AND sr.sr_customer_sk IN (54588, 1262835, 10251139)
      AND sr.sr_return_quantity >= 1
      AND sr.sr_return_amt_inc_tax IS NOT NULL
    GROUP BY sr.sr_store_sk
),
filtered_stores AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_city,
        s.s_number_employees,
        s.s_floor_space,
        s.s_gmt_offset,
        s.s_tax_percentage,
        a.total_return_amt,
        a.total_return_qty,
        a.avg_fee,
        a.cnt_returns
    FROM store s
    INNER JOIN store_return_agg a
        ON s.s_store_sk = a.sr_store_sk
    WHERE s.s_state = 'CA'
      AND s.s_gmt_offset BETWEEN -8 AND -5
      AND s.s_tax_percentage <= 9.00
      AND s.s_floor_space > 15000
      AND s.s_number_employees BETWEEN 50 AND 200
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_ship_cost < 500
      )
)
SELECT
    s_state,
    COUNT(*) AS store_count,
    SUM(total_return_amt) AS sum_return_amt,
    AVG(total_return_qty) AS avg_return_qty,
    AVG(avg_fee) AS avg_fee_per_store
FROM filtered_stores
GROUP BY s_state
HAVING COUNT(*) >= 5
ORDER BY sum_return_amt DESC
LIMIT 100
