WITH returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_reason_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_refunded_cash) AS avg_refunded_cash
    FROM web_returns wr
    WHERE wr.wr_return_quantity >= 5
      AND wr.wr_reason_sk IN (6, 28, 46)
    GROUP BY wr.wr_returned_date_sk, wr.wr_reason_sk
)
SELECT
    d.d_date,
    w.w_warehouse_name,
    w.w_state,
    r.total_return_amt,
    r.return_cnt,
    i.inv_quantity_on_hand,
    CASE
        WHEN r.total_return_amt > (SELECT AVG(total_return_amt) FROM returns_agg) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level,
    RANK() OVER (PARTITION BY w.w_state ORDER BY r.total_return_amt DESC) AS state_return_rank
FROM returns_agg r
JOIN date_dim d ON r.wr_returned_date_sk = d.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND d.d_dow IN (1, 2, 3)
  AND i.inv_quantity_on_hand > 500
  AND w.w_gmt_offset BETWEEN -5.00 AND 0.00
ORDER BY w.w_state, state_return_rank
LIMIT 100
