WITH sampled_sales AS (
   SELECT ss_ticket_number,
          ss_sold_time_sk,
          ss_customer_sk,
          ss_cdemo_sk,
          ss_hdemo_sk,
          ss_store_sk,
          ss_promo_sk,
          ss_ext_sales_price,
          ss_net_profit
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),
intersected_tickets AS (
   SELECT ss_ticket_number AS ticket_number
   FROM sampled_sales
   JOIN promotion ON sampled_sales.ss_promo_sk = promotion.p_promo_sk
   JOIN store ON sampled_sales.ss_store_sk = store.s_store_sk
   JOIN time_dim ON sampled_sales.ss_sold_time_sk = time_dim.t_time_sk
   JOIN customer ON sampled_sales.ss_customer_sk = customer.c_customer_sk
   JOIN customer_demographics ON sampled_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
   JOIN household_demographics ON sampled_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
   WHERE promotion.p_purpose = 'Unknown'
     AND time_dim.t_shift = 'first'
     AND time_dim.t_sub_shift = 'morning'
     AND store.s_state = 'CA'
     AND store.s_zip = '43951'
     AND customer.c_preferred_cust_flag = 'Y'
     AND customer_demographics.cd_gender = 'M'
     AND household_demographics.hd_vehicle_count >= 2
   INTERSECT
   SELECT sr_ticket_number
   FROM store_returns
   JOIN store ON store_returns.sr_store_sk = store.s_store_sk
   JOIN time_dim ON store_returns.sr_return_time_sk = time_dim.t_time_sk
   WHERE time_dim.t_shift = 'first'
     AND time_dim.t_sub_shift = 'morning'
     AND store_returns.sr_fee > 0
     AND store_returns.sr_return_amt > 0
)
SELECT
   store.s_store_name,
   'sale' AS transaction_type,
   COUNT(*) AS txn_count,
   SUM(sampled_sales.ss_ext_sales_price) AS total_amount,
   AVG(sampled_sales.ss_ext_sales_price) AS avg_amount,
   SUM(CASE WHEN sampled_sales.ss_net_profit > 0 THEN sampled_sales.ss_net_profit ELSE 0 END) AS positive_profit,
   MIN(sampled_sales.ss_net_profit) AS min_profit,
   MAX(sampled_sales.ss_net_profit) AS max_profit
FROM sampled_sales
JOIN store ON sampled_sales.ss_store_sk = store.s_store_sk
JOIN intersected_tickets it ON sampled_sales.ss_ticket_number = it.ticket_number
GROUP BY store.s_store_name

UNION DISTINCT

SELECT
   store.s_store_name,
   'return' AS transaction_type,
   COUNT(*) AS txn_count,
   SUM(store_returns.sr_return_amt) AS total_amount,
   AVG(store_returns.sr_return_amt) AS avg_amount,
   SUM(CASE WHEN store_returns.sr_net_loss > 0 THEN store_returns.sr_net_loss ELSE 0 END) AS positive_profit,
   MIN(store_returns.sr_net_loss) AS min_profit,
   MAX(store_returns.sr_net_loss) AS max_profit
FROM store_returns
JOIN store ON store_returns.sr_store_sk = store.s_store_sk
JOIN intersected_tickets it ON store_returns.sr_ticket_number = it.ticket_number
GROUP BY store.s_store_name
