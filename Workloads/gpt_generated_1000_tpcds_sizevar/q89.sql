WITH cs_base AS (
   SELECT
      cs.cs_order_number,
      cs.cs_catalog_page_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_ship_cdemo_sk,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_sales_price,
      ARRAY[cs.cs_quantity, cs.cs_sales_price] AS qty_price_arr
   FROM catalog_sales cs
),
cs_unnested AS (
   SELECT
      b.cs_order_number,
      p.cp_department AS department,
      t.t_hour AS hour_of_day,
      d_bill.cd_gender AS gender,
      metric AS metric_value,
      CASE WHEN metric >= 100 THEN 'high' ELSE 'low' END AS metric_level,
      b.cs_net_profit
   FROM cs_base b
   JOIN catalog_page p
     ON b.cs_catalog_page_sk = p.cp_catalog_page_sk
   JOIN time_dim t
     ON b.cs_sold_time_sk = t.t_time_sk
   JOIN customer_demographics d_bill
     ON b.cs_bill_cdemo_sk = d_bill.cd_demo_sk
   CROSS JOIN UNNEST(b.qty_price_arr) AS u(metric)
),
joined_all AS (
   SELECT
      u.department,
      u.hour_of_day,
      u.gender,
      u.metric_level,
      u.cs_net_profit,
      r.cr_return_amount,
      ss.ss_net_paid_inc_tax
   FROM cs_unnested u
   JOIN catalog_returns r
     ON u.cs_order_number = r.cr_order_number
   JOIN catalog_page p_ret
     ON r.cr_catalog_page_sk = p_ret.cp_catalog_page_sk
   JOIN time_dim t_ret
     ON r.cr_returned_time_sk = t_ret.t_time_sk
   JOIN customer_demographics d_refunded
     ON r.cr_refunded_cdemo_sk = d_refunded.cd_demo_sk
   JOIN customer_demographics d_returning
     ON r.cr_returning_cdemo_sk = d_returning.cd_demo_sk
   JOIN store_sales ss
     ON ss.ss_sold_time_sk = t_ret.t_time_sk
   JOIN customer_demographics d_store
     ON ss.ss_cdemo_sk = d_store.cd_demo_sk
   JOIN time_dim t_store
     ON ss.ss_sold_time_sk = t_store.t_time_sk
)
SELECT
   department,
   hour_of_day,
   gender,
   metric_level,
   SUM(cs_net_profit) AS total_profit,
   COUNT(*) AS transaction_cnt,
   ROW_NUMBER() OVER (PARTITION BY department ORDER BY SUM(cs_net_profit) DESC) AS dept_rank
FROM joined_all
GROUP BY department, hour_of_day, gender, metric_level
HAVING COUNT(*) > 10
ORDER BY total_profit DESC, department
LIMIT 100
