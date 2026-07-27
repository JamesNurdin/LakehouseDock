SELECT
   w.w_warehouse_id,
   w.w_suite_number,
   CAST(regexp_extract(w.w_suite_number, '\\d+') AS integer) AS suite_number,
   CONCAT(w.w_warehouse_id, '-', w.w_suite_number) AS warehouse_suite_key,
   r.r_reason_desc,
   hd.hd_income_band_sk,
   AVG(cr.cr_net_loss) AS avg_net_loss,
   (SELECT AVG(cr2.cr_net_loss) FROM tpcds.catalog_returns cr2) AS overall_avg_net_loss
FROM tpcds.catalog_returns cr
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE regexp_like(r.r_reason_desc, '(?i)job')
  AND w.w_suite_number LIKE 'Suite 9%'
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr
        WHERE sr.sr_hdemo_sk = hd.hd_demo_sk
          AND sr.sr_return_amt > 100
      )
GROUP BY
   w.w_warehouse_id,
   w.w_suite_number,
   CAST(regexp_extract(w.w_suite_number, '\\d+') AS integer),
   CONCAT(w.w_warehouse_id, '-', w.w_suite_number),
   r.r_reason_desc,
   hd.hd_income_band_sk
HAVING AVG(cr.cr_net_loss) > (SELECT AVG(cr3.cr_net_loss) FROM tpcds.catalog_returns cr3)
ORDER BY avg_net_loss DESC
LIMIT 100
