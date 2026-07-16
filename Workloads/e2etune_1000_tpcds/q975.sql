WITH band_state_returns AS (
    SELECT
        ib.ib_income_band_sk AS income_band_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_state,
        COUNT(DISTINCT wr.wr_order_number) AS num_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_fee) AS avg_fee
    FROM income_band ib
    JOIN warehouse w
        ON ib.ib_income_band_sk = (w.w_warehouse_sq_ft % 5) + 1
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = ib.ib_income_band_sk
    WHERE w.w_state IN ('NM', 'OH', 'GA')
      AND ib.ib_lower_bound >= 10001
      AND wr.wr_return_amt > 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, w.w_state
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    income_band_id,
    ib_lower_bound,
    ib_upper_bound,
    w_state,
    num_orders,
    total_return_amount,
    avg_fee,
    RANK() OVER (PARTITION BY income_band_id ORDER BY total_return_amount DESC) AS state_rank_by_return
FROM band_state_returns
ORDER BY total_return_amount DESC
LIMIT 20
