WITH filtered_returns AS (
   SELECT
       cr.cr_warehouse_sk,
       cr.cr_returned_date_sk,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_return_tax,
       cr.cr_reason_sk,
       w.w_warehouse_name,
       d.d_year,
       d.d_month_seq,
       i.i_manager_id,
       r.r_reason_desc,
       hd_ref.hd_income_band_sk AS refunded_income_band,
       hd_ret.hd_income_band_sk AS returning_income_band
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN household_demographics hd_ref
     ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN household_demographics hd_ret
     ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
   JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2001
     AND d.d_moy = 7
     AND i.i_manager_id = 27
     AND w.w_country = 'United States'
     AND w.w_suite_number = 'Suite 260'
     AND r.r_reason_desc = 'Customer not satisfied'
)
SELECT
    u.w_warehouse_name,
    u.d_year,
    u.total_return,
    u.avg_tax,
    u.cnt
FROM (
    SELECT
        fr.w_warehouse_name,
        fr.d_year,
        SUM(fr.cr_return_amount) AS total_return,
        AVG(fr.cr_return_tax) AS avg_tax,
        COUNT(*) AS cnt
    FROM filtered_returns fr
    WHERE fr.cr_return_amount > (
            SELECT MAX(cr_return_amount)
            FROM catalog_returns
            WHERE cr_returned_date_sk = 12345
          )
      AND EXISTS (
            SELECT 1
            FROM reason r2
            WHERE r2.r_reason_sk = fr.cr_reason_sk
              AND r2.r_reason_desc LIKE '%defect%'
          )
    GROUP BY fr.w_warehouse_name, fr.d_year

    UNION

    SELECT
        fr.w_warehouse_name,
        fr.d_year,
        SUM(fr.cr_return_amount) AS total_return,
        AVG(fr.cr_return_tax) AS avg_tax,
        COUNT(*) AS cnt
    FROM filtered_returns fr
    WHERE fr.refunded_income_band = 3
      AND fr.returning_income_band = 4
    GROUP BY fr.w_warehouse_name, fr.d_year
) u
ORDER BY u.total_return DESC
LIMIT 100
