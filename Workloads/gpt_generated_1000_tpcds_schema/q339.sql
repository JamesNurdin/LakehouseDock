WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        d.d_year,
        s.s_store_id,
        s.s_state,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt,
        wr.wr_fee,
        r.r_reason_desc,
        c.c_birth_year,
        ARRAY[wr.wr_return_amt, wr.wr_fee] AS amt_array
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND d.d_year = 2001
      AND inv.inv_quantity_on_hand > 100
      AND wr.wr_return_amt > 1000
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND r.r_reason_desc LIKE '%Warranty%'
),
expanded AS (
    SELECT
        b.cc_call_center_id,
        b.s_store_id,
        b.r_reason_desc,
        b.c_birth_year,
        b.inv_quantity_on_hand,
        b.wr_return_amt,
        amt_sum.sum_amt,
        amt_val.amount
    FROM base b
    CROSS JOIN LATERAL (
        SELECT SUM(v) AS sum_amt
        FROM UNNEST(b.amt_array) AS t(v)
    ) AS amt_sum
    CROSS JOIN UNNEST(b.amt_array) AS amt_val(amount)
),
agg AS (
    SELECT
        e.s_store_id,
        e.r_reason_desc,
        COUNT(DISTINCT e.cc_call_center_id) AS distinct_centers,
        SUM(e.wr_return_amt) AS total_return_amt,
        AVG(e.sum_amt) AS avg_sum_amt
    FROM expanded e
    GROUP BY e.s_store_id, e.r_reason_desc
)
SELECT DISTINCT a.s_store_id,
       a.r_reason_desc,
       a.distinct_centers,
       a.total_return_amt,
       a.avg_sum_amt
FROM agg a
WHERE a.total_return_amt > 5000
EXCEPT
SELECT DISTINCT a.s_store_id,
       a.r_reason_desc,
       a.distinct_centers,
       a.total_return_amt,
       a.avg_sum_amt
FROM agg a
WHERE a.avg_sum_amt < 1000
ORDER BY total_return_amt DESC
LIMIT 100
