WITH aggregated AS (
    SELECT
        d.d_year,
        s.s_state,
        cc.cc_division_name,
        SUM(wr.wr_return_amt)         AS total_return_amt,
        SUM(wr.wr_return_quantity)    AS total_return_qty,
        SUM(wr.wr_net_loss)           AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d   ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s      ON s.s_closed_date_sk     = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                   -- filter 1
      AND d.d_quarter_seq IN (5, 9, 16)                      -- filter 2
      AND wr.wr_return_ship_cost > 50.0                     -- filter 3
      AND s.s_number_employees BETWEEN 200 AND 300          -- filter 4
      AND cc.cc_state = 'CA'                                -- filter 5
    GROUP BY ROLLUP (d.d_year, s.s_state, cc.cc_division_name)
)
SELECT
    d_year,
    s_state,
    cc_division_name,
    total_return_amt,
    total_return_qty,
    total_net_loss,
    CASE WHEN total_net_loss > 10000 THEN 'High' ELSE 'Low' END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS row_num,
    RANK()       OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rnk
FROM aggregated
ORDER BY d_year, s_state, row_num
LIMIT 100
