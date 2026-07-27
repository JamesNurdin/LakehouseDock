WITH sr_agg AS (
    SELECT
        sr_return_time_sk,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_fee) AS avg_fee,
        COUNT(DISTINCT sr_ticket_number) AS cnt_tickets,
        MIN(sr_return_quantity) AS min_qty,
        MAX(sr_return_ship_cost) AS max_ship_cost
    FROM store_returns
    WHERE sr_store_credit > 10.00
      AND sr_fee BETWEEN 5.00 AND 80.00
      AND sr_return_quantity >= 1
      AND sr_addr_sk IN (2461223, 4231946, 2873423)
      AND sr_return_amt_inc_tax < 500.00
    GROUP BY sr_return_time_sk
)
SELECT
    td.t_hour,
    td.t_sub_shift,
    SUM(sr.total_return_amt) AS sum_return_amt,
    AVG(sr.avg_fee) AS avg_fee_over_time,
    SUM(sr.cnt_tickets) AS total_tickets,
    MIN(sr.min_qty) AS overall_min_qty,
    MAX(sr.max_ship_cost) AS overall_max_ship_cost
FROM sr_agg sr
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 12 AND 18
  AND td.t_sub_shift = 'afternoon'
  AND td.t_time IN (15, 16, 19)
  AND td.t_am_pm = 'PM'
  AND td.t_minute = 0
GROUP BY td.t_hour, td.t_sub_shift
ORDER BY td.t_hour ASC, sum_return_amt DESC
