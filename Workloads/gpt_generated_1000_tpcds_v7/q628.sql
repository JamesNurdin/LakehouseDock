WITH joined AS (
   SELECT
      s.s_store_sk,
      s.s_store_id,
      s.s_store_name,
      s.s_state,
      ss.ss_net_profit,
      cr.cr_return_amount,
      p.p_channel_catalog,
      p.p_cost,
      c.c_birth_year
   FROM tpcds.store_sales ss
   JOIN tpcds.item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN tpcds.promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   JOIN tpcds.store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN tpcds.customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN tpcds.catalog_returns cr
     ON i.i_item_sk = cr.cr_item_sk
   JOIN tpcds.call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   WHERE p.p_channel_catalog = 'Y'
     AND p.p_cost > 1000
     AND s.s_state = 'CA'
     AND c.c_birth_year BETWEEN 1950 AND 1960
     AND cr.cr_return_quantity > 1
),
agg AS (
   SELECT
      s_store_id,
      s_store_name,
      s_state,
      SUM(ss_net_profit) AS total_sales_profit,
      SUM(cr_return_amount) AS total_return_amount
   FROM joined
   GROUP BY s_store_id, s_store_name, s_state
)
SELECT
   s_store_id,
   s_store_name,
   s_state,
   total_sales_profit,
   total_return_amount,
   ROW_NUMBER() OVER (ORDER BY total_sales_profit DESC) AS profit_rank,
   CASE
      WHEN total_sales_profit > total_return_amount THEN 'Profit > Returns'
      ELSE 'Loss or Equal'
   END AS profit_vs_return_flag
FROM agg
ORDER BY profit_rank
LIMIT 20
