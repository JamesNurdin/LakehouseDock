WITH sales_agg AS (
 SELECT
   d.d_year,
   d.d_month_seq AS month,
   s.s_state,
   i.i_category,
   p.p_promo_name,
   SUM(ss.ss_net_paid) AS total_net_paid,
   SUM(ss.ss_net_profit) AS total_net_profit,
   SUM(ss.ss_quantity) AS total_quantity,
   AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
   COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 WHERE d.d_year = 1998
 GROUP BY
   d.d_year,
   d.d_month_seq,
   s.s_state,
   i.i_category,
   p.p_promo_name
),
ranked_sales AS (
 SELECT
   *,
   ROW_NUMBER() OVER (PARTITION BY d_year, month ORDER BY total_net_paid DESC) AS rank_by_sales
 FROM sales_agg
)
SELECT
   d_year,
   month,
   s_state,
   i_category,
   p_promo_name,
   total_net_paid,
   total_net_profit,
   total_quantity,
   avg_discount_amt,
   num_transactions,
   rank_by_sales
FROM ranked_sales
WHERE rank_by_sales <= 10
ORDER BY d_year, month, rank_by_sales
