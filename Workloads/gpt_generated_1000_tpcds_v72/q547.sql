WITH base AS (
   SELECT
       s.s_store_id,
       d.d_year,
       i.i_item_id,
       i.i_units,
       cd.cd_credit_rating,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       ss.ss_net_profit,
       sr.sr_net_loss,
       cr.cr_net_loss,
       wr.wr_net_loss,
       sm.sm_carrier,
       r_sr.r_reason_desc AS store_return_reason,
       r_cr.r_reason_desc AS catalog_return_reason,
       r_wr.r_reason_desc AS web_return_reason,
       p.p_promo_name,
       cp.cp_department,
       cc.cc_name AS call_center_name,
       ca.ca_city,
       t_sr.t_hour
   FROM store s
   JOIN store_sales ss
       ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d
       ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p
       ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer c
       ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
       ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
       ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_returns sr
       ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r_sr
       ON sr.sr_reason_sk = r_sr.r_reason_sk
   JOIN time_dim t_sr
       ON sr.sr_return_time_sk = t_sr.t_time_sk
   JOIN catalog_returns cr
       ON cr.cr_item_sk = i.i_item_sk
      AND cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason r_cr
       ON cr.cr_reason_sk = r_cr.r_reason_sk
   JOIN ship_mode sm
       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
       ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN web_returns wr
       ON wr.wr_item_sk = i.i_item_sk
      AND wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r_wr
       ON wr.wr_reason_sk = r_wr.r_reason_sk
   JOIN web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN customer_address ca
       ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN inventory inv
       ON inv.inv_item_sk = i.i_item_sk
      AND inv.inv_date_sk = d.d_date_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2002
     AND i.i_units = 'Case'
     AND cd.cd_credit_rating = 'Good'
     AND ib.ib_upper_bound >= 50000
     AND s.s_state = 'CA'
     AND sm.sm_carrier = 'AIRBORNE'
),
agg_per_store AS (
   SELECT
       s_store_id,
       d_year,
       SUM(ss_net_profit) AS total_profit,
       SUM(COALESCE(sr_net_loss, 0)) AS total_store_return_loss,
       SUM(COALESCE(cr_net_loss, 0)) AS total_catalog_return_loss,
       SUM(COALESCE(wr_net_loss, 0)) AS total_web_return_loss
   FROM base
   GROUP BY s_store_id, d_year
),
agg_year AS (
   SELECT
       d_year,
       AVG(total_profit) AS avg_profit_per_store,
       SUM(total_store_return_loss + total_catalog_return_loss + total_web_return_loss) AS total_all_returns
   FROM agg_per_store
   GROUP BY d_year
   HAVING AVG(total_profit) > 10000
)
SELECT d_year,
       avg_profit_per_store,
       total_all_returns
FROM agg_year
UNION ALL
SELECT d_year,
       NULL AS avg_profit_per_store,
       SUM(total_store_return_loss + total_catalog_return_loss + total_web_return_loss) AS total_all_returns
FROM agg_per_store
GROUP BY d_year
ORDER BY d_year DESC
