WITH inventory_daily AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk
)
SELECT
    d.d_date,
    s.s_store_name,
    i.total_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_refunded_customers,
    AVG(wr.wr_return_ship_cost) AS avg_ship_cost
FROM date_dim d
JOIN inventory_daily i
    ON i.inv_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 1999
  AND d.d_day_name = 'Friday'
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND s.s_gmt_offset = -5.00
  AND s.s_number_employees >= 100
  AND wr.wr_return_ship_cost > 100.00
  AND wr.wr_return_amt_inc_tax < 500.00
GROUP BY d.d_date, s.s_store_name, i.total_qty
ORDER BY total_return_amt DESC
LIMIT 100
