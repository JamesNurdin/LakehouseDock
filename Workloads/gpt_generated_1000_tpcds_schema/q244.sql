WITH recent_dates AS (
   SELECT d.d_date_sk,
          d.d_date,
          d.d_month_seq,
          d.d_year
   FROM date_dim d
   WHERE d.d_year = 2001
     AND d.d_current_month = 'Y'
)
SELECT
    rd.d_date,
    r.r_reason_desc,
    CONCAT(r.r_reason_desc, ' - ', CAST(rd.d_month_seq AS VARCHAR)) AS reason_month,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\d+)', 1) AS reason_first_number,
    cp.cp_type,
    SUBSTRING(cc.cc_hours FROM 1 FOR 2) AS cc_hours_prefix,
    cr_sum.total_return_amount,
    ROW_NUMBER() OVER (ORDER BY cr_sum.total_return_amount DESC) AS rn
FROM recent_dates rd
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = rd.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN LATERAL (
    SELECT SUM(cr2.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr2
    WHERE cr2.cr_returned_date_sk = rd.d_date_sk
      AND cr2.cr_reason_sk = r.r_reason_sk
) cr_sum ON TRUE
WHERE REGEXP_LIKE(r.r_reason_desc, '^.*[0-9].*$')
  AND r.r_reason_desc LIKE '%refund%'
  AND REGEXP_LIKE(cp.cp_type, 'annual')
  AND cc.cc_class = 'large'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk = rd.d_date_sk
          AND sr.sr_reason_sk = r.r_reason_sk
          AND sr.sr_return_amt > 0
      )
ORDER BY cr_sum.total_return_amount DESC
LIMIT 100
