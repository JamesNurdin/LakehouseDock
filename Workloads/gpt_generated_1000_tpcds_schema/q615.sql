WITH catalog_fact AS (
   SELECT cr.cr_returned_date_sk AS ret_date_sk,
          cr.cr_returned_time_sk AS ret_time_sk,
          cr.cr_return_quantity   AS ret_qty,
          cr.cr_return_amt_inc_tax AS ret_amt,
          cr.cr_call_center_sk,
          cr.cr_catalog_page_sk,
          cr.cr_ship_mode_sk,
          cr.cr_refunded_customer_sk,
          cr.cr_refunded_cdemo_sk,
          cr.cr_refunded_hdemo_sk,
          cr.cr_refunded_addr_sk
   FROM catalog_returns cr
),
web_fact AS (
   SELECT wr.wr_returned_date_sk AS ret_date_sk,
          wr.wr_returned_time_sk AS ret_time_sk,
          wr.wr_return_quantity   AS ret_qty,
          wr.wr_return_amt_inc_tax AS ret_amt,
          NULL AS cr_call_center_sk,
          NULL AS cr_catalog_page_sk,
          NULL AS cr_ship_mode_sk,
          wr.wr_refunded_customer_sk AS cr_refunded_customer_sk,
          wr.wr_refunded_cdemo_sk   AS cr_refunded_cdemo_sk,
          wr.wr_refunded_hdemo_sk   AS cr_refunded_hdemo_sk,
          wr.wr_refunded_addr_sk   AS cr_refunded_addr_sk
   FROM web_returns wr
),
union_facts AS (
   SELECT * FROM catalog_fact
   UNION
   SELECT * FROM web_fact
)
SELECT
   d_ret.d_year,
   d_ret.d_month_seq,
   sm.sm_ship_mode_id,
   cp.cp_type,
   cc.cc_name,
   c.c_first_name,
   c.c_last_name,
   hd.hd_buy_potential,
   SUM(u.ret_amt)                     AS total_return_amount,
   COUNT(*)                           AS total_returns,
   ROW_NUMBER() OVER (PARTITION BY d_ret.d_year ORDER BY SUM(u.ret_amt) DESC) AS rn_yearly,
   lp.avg_page_return
FROM union_facts u
LEFT JOIN date_dim d_ret ON u.ret_date_sk = d_ret.d_date_sk
LEFT JOIN time_dim t_ret ON u.ret_time_sk = t_ret.t_time_sk
LEFT JOIN ship_mode sm ON u.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_page cp ON u.cr_catalog_page_sk = cp.cp_catalog_page_sk
RIGHT JOIN call_center cc ON u.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN customer c ON u.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON u.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON u.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_address ca ON u.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN date_dim d_store ON 1=1
RIGHT JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
LEFT JOIN LATERAL (
   SELECT AVG(cr2.cr_return_amt_inc_tax) AS avg_page_return
   FROM catalog_returns cr2
   WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
) lp ON TRUE
WHERE EXISTS (
   SELECT 1 FROM ship_mode sm2 WHERE sm2.sm_contract LIKE 'fop%'
)
GROUP BY
   d_ret.d_year,
   d_ret.d_month_seq,
   sm.sm_ship_mode_id,
   cp.cp_type,
   cc.cc_name,
   c.c_first_name,
   c.c_last_name,
   hd.hd_buy_potential,
   lp.avg_page_return
HAVING SUM(u.ret_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
