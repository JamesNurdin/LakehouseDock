SELECT
   cc.cc_name,
   d_store.d_year AS year,
   sm.sm_type,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
   SUM(ss.ss_net_profit) AS store_profit,
   SUM(cs.cs_net_profit) AS catalog_profit,
   SUM(cr.cr_net_loss) AS return_loss,
   SUM(ss.ss_net_profit + cs.cs_net_profit - cr.cr_net_loss) AS net_contribution
FROM
   store_sales ss
   JOIN date_dim d_store
     ON ss.ss_sold_date_sk = d_store.d_date_sk
   JOIN household_demographics hd_store
     ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
   JOIN income_band ib
     ON hd_store.hd_income_band_sk = ib.ib_income_band_sk
   JOIN catalog_sales cs
     ON cs.cs_sold_date_sk = d_store.d_date_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd_bill
     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   JOIN date_dim d_return
     ON cr.cr_returned_date_sk = d_return.d_date_sk
   JOIN household_demographics hd_refunded
     ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
   JOIN household_demographics hd_returning
     ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
   JOIN call_center cc_ret
     ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
   JOIN catalog_page cp_ret
     ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
   JOIN ship_mode sm_ret
     ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
   JOIN inventory inv
     ON inv.inv_date_sk = d_store.d_date_sk
WHERE
   d_store.d_year = 2001
   AND cc.cc_state = 'CA'
GROUP BY
   cc.cc_name,
   d_store.d_year,
   sm.sm_type,
   ib.ib_lower_bound,
   ib.ib_upper_bound
ORDER BY
   net_contribution DESC
LIMIT 100
