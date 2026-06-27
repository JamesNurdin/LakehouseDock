WITH hourly_store_sales AS (
   SELECT
       s.s_store_id,
       s.s_store_name,
       t.t_hour,
       cd.cd_gender,
       i.i_category,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       SUM(ss.ss_ext_discount_amt) AS total_discount,
       COUNT(*) AS transaction_count
   FROM store_sales ss
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
   WHERE p.p_discount_active = 'Y'
   GROUP BY s.s_store_id, s.s_store_name, t.t_hour, cd.cd_gender, i.i_category
),
ranked_sales AS (
   SELECT
       s_store_id,
       s_store_name,
       t_hour,
       cd_gender,
       i_category,
       total_sales,
       total_profit,
       total_discount,
       transaction_count,
       total_discount / nullif(total_sales, 0) AS discount_rate,
       row_number() OVER (PARTITION BY t_hour ORDER BY total_profit DESC) AS profit_rank
   FROM hourly_store_sales
)
SELECT
   s_store_id,
   s_store_name,
   t_hour,
   cd_gender,
   i_category,
   total_sales,
   total_profit,
   total_discount,
   transaction_count,
   discount_rate,
   profit_rank
FROM ranked_sales
WHERE profit_rank <= 5
ORDER BY t_hour, profit_rank
