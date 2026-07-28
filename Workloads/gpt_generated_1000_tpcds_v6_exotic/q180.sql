WITH joined_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        i.i_brand,
        i.i_category,
        r.r_reason_desc,
        t.t_am_pm,
        t.t_sub_shift,
        ib.ib_upper_bound,
        hd_refunded.hd_vehicle_count
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib
        ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
        AND t.t_time_sk = wr.wr_returned_time_sk
        AND r.r_reason_sk = wr.wr_reason_sk
        AND hd_refunded.hd_demo_sk = wr.wr_refunded_hdemo_sk
)
SELECT
    i_brand,
    r_reason_desc,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    COUNT(*) AS return_rows,
    AVG(cr_return_quantity) AS avg_catalog_quantity,
    MIN(cr_return_amount) AS min_catalog_return_amount
FROM joined_returns
WHERE r_reason_desc LIKE '%color%'
  AND t_am_pm = 'PM'
  AND t_sub_shift = 'evening'
  AND ib_upper_bound >= 150000
  AND hd_vehicle_count >= 2
  AND cr_return_quantity > 1
GROUP BY GROUPING SETS ((i_brand, r_reason_desc), (i_brand))
HAVING SUM(cr_return_amount) > 10000
ORDER BY total_catalog_return_amount DESC
LIMIT 100
