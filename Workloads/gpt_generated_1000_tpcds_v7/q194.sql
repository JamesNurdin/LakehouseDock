WITH joined_data AS (
   SELECT
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      cs.cs_net_profit AS cs_profit,
      ss.ss_net_profit AS ss_profit,
      ws.ws_net_profit AS ws_profit,
      cc.cc_state,
      cp.cp_department,
      cd.cd_gender,
      ib.ib_lower_bound,
      cr.cr_return_amount,
      ws.ws_quantity
   FROM catalog_sales cs
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN store_sales ss
     ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN web_sales ws
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cc.cc_state = 'CA'
     AND cp.cp_department = 'Electronics'
     AND cd.cd_gender = 'M'
     AND ib.ib_lower_bound >= 50000
     AND cr.cr_return_amount > 100.00
     AND ws.ws_quantity > 5
)
SELECT
   c_customer_id,
   c_first_name,
   c_last_name,
   total_profit,
   RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
   CASE WHEN total_profit >= 1000 THEN 'High' ELSE 'Medium' END AS profit_category
FROM (
   SELECT
      c_customer_id,
      c_first_name,
      c_last_name,
      (COALESCE(cs_profit, 0) + COALESCE(ss_profit, 0) + COALESCE(ws_profit, 0)) AS total_profit
   FROM joined_data
) agg
ORDER BY profit_rank
LIMIT 100
