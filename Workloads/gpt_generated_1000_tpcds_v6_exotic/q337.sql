WITH sales_agg AS (
   SELECT
       cs.cs_call_center_sk,
       cs.cs_ship_mode_sk,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_promo_sk,
       cs.cs_bill_customer_sk,
       cs.cs_bill_addr_sk,
       cs.cs_bill_cdemo_sk,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit
   FROM catalog_sales cs
   GROUP BY
       cs.cs_call_center_sk,
       cs.cs_ship_mode_sk,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_promo_sk,
       cs.cs_bill_customer_sk,
       cs.cs_bill_addr_sk,
       cs.cs_bill_cdemo_sk
),
returns_agg AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_reason_sk,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_net_loss) AS total_return_loss
   FROM web_returns wr
   GROUP BY wr.wr_returned_date_sk, wr.wr_reason_sk
),
joined_data AS (
   SELECT
       cc.cc_call_center_id,
       cc.cc_name,
       sm.sm_ship_mode_id,
       d_sales.d_year,
       p.p_promo_name,
       cd.cd_gender,
       ca.ca_state,
       r.r_reason_desc,
       sa.total_sales,
       sa.total_profit,
       ra.total_return_amount,
       ra.total_return_loss
   FROM sales_agg sa
   JOIN date_dim d_sales
       ON sa.cs_sold_date_sk = d_sales.d_date_sk
   JOIN time_dim td
       ON sa.cs_sold_time_sk = td.t_time_sk
   JOIN call_center cc
       ON sa.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
       ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
       ON sa.cs_promo_sk = p.p_promo_sk
   JOIN customer c
       ON sa.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca
       ON sa.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
       ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN returns_agg ra
       ON sa.cs_sold_date_sk = ra.wr_returned_date_sk
   LEFT JOIN reason r
       ON ra.wr_reason_sk = r.r_reason_sk
   JOIN web_site ws
       ON ws.web_open_date_sk = d_sales.d_date_sk
   WHERE d_sales.d_year = 2001
     AND cc.cc_state = 'CA'
     AND sm.sm_carrier = 'UPS'
     AND p.p_discount_active = 'Y'
     AND td.t_hour BETWEEN 9 AND 18
)
SELECT
    j.cc_call_center_id,
    j.cc_name,
    j.sm_ship_mode_id,
    SUM(j.total_sales) AS sum_sales,
    SUM(j.total_profit) AS sum_profit,
    SUM(COALESCE(j.total_return_amount, 0)) AS sum_returns,
    SUM(COALESCE(j.total_return_loss, 0)) AS sum_return_loss,
    (SUM(j.total_sales) - SUM(COALESCE(j.total_return_amount, 0))) AS net_sales,
    (SUM(j.total_profit) - SUM(COALESCE(j.total_return_loss, 0))) AS net_profit
FROM joined_data j
GROUP BY j.cc_call_center_id, j.cc_name, j.sm_ship_mode_id
HAVING SUM(j.total_sales) > 100000
ORDER BY net_profit DESC
LIMIT 100
