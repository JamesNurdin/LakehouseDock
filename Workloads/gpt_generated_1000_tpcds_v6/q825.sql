WITH agg AS (
    SELECT
        d.d_year,
        w.w_city,
        cc.cc_division,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        SUM(CASE WHEN wr.wr_return_tax > 20 THEN 1 ELSE 0 END) AS high_tax_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND i.inv_quantity_on_hand > 100
      AND wr.wr_return_tax > 0
      AND hd.hd_vehicle_count >= 2
      AND cc.cc_employees BETWEEN 50 AND 200
    GROUP BY ROLLUP (d.d_year, w.w_city, cc.cc_division)
)
SELECT
    d_year,
    w_city,
    cc_division,
    total_return_amt,
    total_quantity,
    avg_return_tax,
    high_tax_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rn_within_year
FROM agg
ORDER BY d_year, w_city, cc_division
LIMIT 100
