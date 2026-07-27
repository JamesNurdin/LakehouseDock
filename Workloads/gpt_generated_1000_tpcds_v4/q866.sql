SELECT
    d.d_year,
    d.d_month_seq,
    cd_ref.cd_gender,
    w.w_warehouse_name,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    MIN(wr.wr_return_tax) AS min_return_tax,
    MAX(wr.wr_return_tax) AS max_return_tax
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON wr.wr_returned_time_sk = t.t_time_sk
JOIN customer_demographics cd_ref
  ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref
  ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1210
    AND t.t_hour BETWEEN 9 AND 17
    AND cd_ref.cd_gender = 'M'
    AND w.w_country = 'United States'
    AND EXISTS (
        SELECT 1
        FROM income_band ib
        WHERE ib.ib_income_band_sk = hd_ref.hd_income_band_sk
          AND ib.ib_lower_bound >= 30000
    )
GROUP BY
    d.d_year,
    d.d_month_seq,
    cd_ref.cd_gender,
    w.w_warehouse_name
ORDER BY
    total_return_amount DESC
LIMIT 100
