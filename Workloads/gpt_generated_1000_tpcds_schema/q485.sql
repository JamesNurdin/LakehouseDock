WITH joined_data AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       cd.cd_gender,
       cd.cd_education_status,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       i.i_item_sk,
       i.i_category,
       i.i_current_price,
       p.p_promo_id,
       t_cs.t_hour AS cs_hour,
       ss.ss_net_paid_inc_tax AS ss_net_paid,
       cs.cs_net_paid_inc_tax AS cs_net_paid,
       sr.sr_net_loss AS sr_net_loss,
       cr.cr_net_loss AS cr_net_loss,
       r_sr.r_reason_desc AS store_return_reason,
       cc.cc_name AS call_center_name
   FROM customer c
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
   JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
   JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
   JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
   JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
   LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   LEFT JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
   WHERE c.c_birth_year BETWEEN 1950 AND 1960
     AND i.i_current_price > 50
     AND p.p_discount_active = 'Y'
     AND t_cs.t_hour BETWEEN 9 AND 17
),
agg_data AS (
   SELECT
       cd_gender,
       hd_buy_potential,
       i_category,
       SUM(ss_net_paid) AS total_store_sales,
       SUM(cs_net_paid) AS total_catalog_sales,
       SUM(sr_net_loss) AS total_store_return_loss,
       SUM(cr_net_loss) AS total_catalog_return_loss,
       COUNT(*) AS txn_count
   FROM joined_data
   GROUP BY CUBE (cd_gender, hd_buy_potential, i_category)
)
SELECT
   a.cd_gender,
   a.hd_buy_potential,
   a.i_category,
   a.total_store_sales,
   a.total_catalog_sales,
   a.total_store_return_loss,
   a.total_catalog_return_loss,
   a.txn_count,
   mp.max_item_price,
   RANK() OVER (PARTITION BY a.cd_gender ORDER BY a.total_store_sales DESC) AS gender_sales_rank
FROM agg_data a
LEFT JOIN LATERAL (
   SELECT MAX(i2.i_current_price) AS max_item_price
   FROM item i2
   WHERE i2.i_category = a.i_category
) mp ON TRUE
WHERE a.total_store_sales > 1000
  AND a.txn_count >= 10
ORDER BY gender_sales_rank
LIMIT 100
