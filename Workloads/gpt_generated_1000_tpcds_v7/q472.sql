WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state,
        ws.web_name,
        wr.wr_return_amt,
        i.inv_quantity_on_hand,
        wr.wr_return_quantity,
        wr.wr_order_number
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND i.inv_quantity_on_hand > 100
      AND s.s_market_desc LIKE '%bars%'
      AND wr.wr_return_quantity > 10
)
SELECT
    d_year,
    s_state,
    web_name,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_quantity_on_hand,
    COUNT(DISTINCT wr_order_number) AS distinct_orders
FROM joined_data
GROUP BY ROLLUP (d_year, s_state, web_name)
ORDER BY d_year, s_state, web_name
