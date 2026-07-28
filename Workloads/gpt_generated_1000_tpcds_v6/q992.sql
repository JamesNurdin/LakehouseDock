WITH distinct_hd AS (
    SELECT DISTINCT hd_demo_sk
    FROM household_demographics
    WHERE hd_buy_potential = '5001-10000'
),
agg_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt)            AS total_return_amt,
        SUM(sr.sr_return_quantity)       AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    WHERE sr.sr_return_amt > 0                     -- filter predicate 1
    GROUP BY
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk
)
SELECT
    d.d_year,
    d.d_date,
    hd.hd_buy_potential,
    r.r_reason_desc,
    t.t_hour,
    ar.total_return_amt,
    ar.total_return_qty,
    ar.distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ar.total_return_amt DESC) AS yearly_rank
FROM agg_returns ar
JOIN distinct_hd dh
  ON ar.sr_hdemo_sk = dh.hd_demo_sk
JOIN date_dim d
  ON ar.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON ar.sr_return_time_sk = t.t_time_sk
JOIN household_demographics hd
  ON ar.sr_hdemo_sk = hd.hd_demo_sk
JOIN reason r
  ON ar.sr_reason_sk = r.r_reason_sk
WHERE d.d_year BETWEEN 1998 AND 2000                     -- predicate 2
  AND hd.hd_dep_count >= 3                               -- predicate 3
  AND hd.hd_vehicle_count <= 2                           -- predicate 4
  AND r.r_reason_desc LIKE '%damaged%'                   -- predicate 5
  AND t.t_hour BETWEEN 9 AND 17                          -- predicate 6
GROUP BY ROLLUP (
    d.d_year,
    d.d_date,
    hd.hd_buy_potential,
    r.r_reason_desc,
    t.t_hour,
    ar.total_return_amt,
    ar.total_return_qty,
    ar.distinct_tickets
)
ORDER BY d.d_year NULLS LAST, yearly_rank
LIMIT 100
