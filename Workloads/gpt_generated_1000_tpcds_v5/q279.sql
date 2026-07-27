WITH joined_data AS (
   SELECT DISTINCT
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      s.s_store_id,
      s.s_state AS store_state,
      ca_sr.ca_city AS return_city,
      cs.cs_net_profit,
      cs.cs_ext_sales_price,
      cs.cs_quantity,
      cc.cc_name,
      cp.cp_department,
      sm.sm_type,
      p.p_promo_id,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      ca_wr_ret.ca_city AS returning_city
   FROM store_returns sr
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN customer_address ca_sr
     ON sr.sr_addr_sk = ca_sr.ca_address_sk
   JOIN catalog_sales cs
     ON cs.cs_bill_addr_sk = ca_sr.ca_address_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN web_returns wr
     ON wr.wr_refunded_addr_sk = ca_sr.ca_address_sk
   JOIN customer_address ca_wr_ret
     ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
   WHERE s.s_state = 'TX'
     AND sr.sr_return_amt > 100
     AND cc.cc_state = 'CA'
     AND p.p_channel_tv = 'N'
     AND sm.sm_type = 'AIR'
)
SELECT
   jd.s_store_id,
   jd.store_state,
   jd.return_city,
   jd.cc_name,
   jd.cp_department,
   jd.sm_type,
   jd.p_promo_id,
   SUM(jd.cs_ext_sales_price) AS total_sales,
   SUM(jd.cs_net_profit) AS total_profit,
   SUM(jd.sr_return_amt) AS total_store_return_amt,
   SUM(jd.wr_return_amt) AS total_web_return_amt,
   ROW_NUMBER() OVER (PARTITION BY jd.s_store_id ORDER BY SUM(jd.cs_ext_sales_price) DESC) AS sales_rank,
   DENSE_RANK() OVER (ORDER BY SUM(jd.cs_net_profit) DESC) AS profit_dense_rank
FROM joined_data jd
GROUP BY
   jd.s_store_id,
   jd.store_state,
   jd.return_city,
   jd.cc_name,
   jd.cp_department,
   jd.sm_type,
   jd.p_promo_id
HAVING SUM(jd.cs_ext_sales_price) > 1000
ORDER BY total_profit DESC, sales_rank
LIMIT 100
