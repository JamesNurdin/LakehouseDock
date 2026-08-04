WITH high_loss_dates AS (
    SELECT sr_returned_date_sk AS d_sk
    FROM store_returns
    WHERE sr_net_loss > 500
    EXCEPT
    SELECT inv_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand < 200
),
inv_data AS (
    SELECT i.inv_date_sk,
           i.inv_item_sk,
           i.inv_quantity_on_hand,
           d.d_year,
           d.d_month_seq
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND d.d_holiday = 'N'
      AND i.inv_quantity_on_hand > 400
),
ret_data AS (
    SELECT sr.sr_returned_date_sk,
           sr.sr_return_time_sk,
           sr.sr_hdemo_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt_inc_tax,
           d.d_year,
           d.d_month_seq,
           t.t_meal_time,
           hd.hd_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_meal_time = 'lunch'
      AND sr.sr_return_quantity BETWEEN 2 AND 5
      AND sr.sr_return_amt_inc_tax > 50
      AND d.d_date_sk IN (SELECT d_sk FROM high_loss_dates)
),
full_joined AS (
    SELECT
        COALESCE(i.d_year, r.d_year) AS year,
        COALESCE(i.d_month_seq, r.d_month_seq) AS month_seq,
        r.ib_lower_bound,
        r.ib_upper_bound,
        i.inv_quantity_on_hand,
        r.sr_return_quantity,
        r.sr_return_amt_inc_tax
    FROM inv_data i
    FULL OUTER JOIN ret_data r
        ON i.inv_date_sk = r.sr_returned_date_sk
),
cross_joined AS (
    SELECT fj.*, ib_flag.flag
    FROM full_joined fj
    CROSS JOIN (VALUES (1), (2)) AS ib_flag(flag)
)
SELECT
    year,
    month_seq,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS cnt_returns,
    SUM(sr_return_amt_inc_tax) AS total_return_amt,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    MIN(sr_return_amt_inc_tax) AS min_return_amt,
    MAX(sr_return_amt_inc_tax) AS max_return_amt,
    (SELECT AVG(sr_return_amt_inc_tax) FROM store_returns) AS overall_avg_return_amt
FROM cross_joined
WHERE flag = 1
GROUP BY ROLLUP (year, month_seq, ib_lower_bound, ib_upper_bound)
HAVING COUNT(*) > 10
ORDER BY year, month_seq, ib_lower_bound
