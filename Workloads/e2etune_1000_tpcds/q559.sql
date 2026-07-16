SELECT
    cp.cp_department,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    i.i_category,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_qty
FROM store_returns sr
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN promotion p
    ON i.i_item_sk = p.p_item_sk
    AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp
    ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
WHERE cp.cp_department = 'DEPARTMENT'
  AND d.d_year = 2022
  AND p.p_discount_active = 'Y'
GROUP BY cp.cp_department, ib.ib_lower_bound, ib.ib_upper_bound, i.i_category
HAVING COUNT(*) > 50
ORDER BY total_refunded_cash DESC
LIMIT 20
