SELECT
    d_date.d_year,
    cd_sales.cd_gender,
    hd_sales.hd_buy_potential,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS return_txn_cnt
FROM store_sales ss
JOIN date_dim d_date
  ON ss.ss_sold_date_sk = d_date.d_date_sk
JOIN customer_demographics cd_sales
  ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN household_demographics hd_sales
  ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_date.d_date_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd_refund
  ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN household_demographics hd_refund
  ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_date.d_date_sk
WHERE d_date.d_current_quarter = 'Y'
  AND cd_sales.cd_gender = 'M'
  AND hd_sales.hd_vehicle_count >= 0
GROUP BY ROLLUP (d_date.d_year, cd_sales.cd_gender, hd_sales.hd_buy_potential)
ORDER BY d_date.d_year ASC NULLS LAST,
         cd_sales.cd_gender ASC NULLS LAST,
         hd_sales.hd_buy_potential ASC NULLS LAST
LIMIT 100
