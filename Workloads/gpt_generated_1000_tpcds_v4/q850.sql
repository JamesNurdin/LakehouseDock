WITH return_agg AS (
   SELECT
      cc.cc_call_center_id,
      cp.cp_catalog_page_id,
      w.w_warehouse_id,
      d.d_year,
      SUM(cr.cr_return_amount)            AS total_return_amount,
      COUNT(*)                           AS return_cnt,
      AVG(cr.cr_return_tax)              AS avg_return_tax
   FROM catalog_returns cr
   JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
     AND cr.cr_return_amount > 100
     AND w.w_state = 'CA'
     AND ib.ib_upper_bound > 50000
     AND c.c_birth_year BETWEEN 1980 AND 1995
   GROUP BY cc.cc_call_center_id, cp.cp_catalog_page_id, w.w_warehouse_id, d.d_year
)
SELECT
   ra.d_year,
   AVG(ra.total_return_amount) AS avg_total_return_amount,
   SUM(ra.return_cnt)          AS total_returns
FROM return_agg ra
WHERE EXISTS (
   SELECT 1
   FROM call_center cc2
   WHERE cc2.cc_call_center_id = ra.cc_call_center_id
     AND cc2.cc_employees > 20
)
GROUP BY ra.d_year
HAVING AVG(ra.total_return_amount) > 500
ORDER BY ra.d_year DESC
LIMIT 100
