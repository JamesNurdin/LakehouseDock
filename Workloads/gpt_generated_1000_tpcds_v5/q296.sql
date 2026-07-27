WITH agg AS (
   SELECT
       d_cs_sold.d_year AS year,
       p_ss.p_promo_name AS promo_name,
       SUM(ss.ss_net_profit) AS total_store_profit,
       SUM(cs.cs_net_paid) AS total_catalog_paid,
       SUM(cr.cr_net_loss) AS total_return_loss,
       CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
       COUNT(DISTINCT c_ss.c_customer_sk) AS distinct_store_customers
   FROM catalog_sales cs
   JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
   JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
   JOIN customer c_cs_bill ON cs.cs_bill_customer_sk = c_cs_bill.c_customer_sk
   JOIN customer_demographics cd_cs_bill ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
   JOIN customer c_cs_ship ON cs.cs_ship_customer_sk = c_cs_ship.c_customer_sk
   JOIN customer_demographics cd_cs_ship ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
   JOIN date_dim d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
   JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
   JOIN customer c_cr_refunded ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
   JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
   JOIN customer c_cr_returning ON cr.cr_returning_customer_sk = c_cr_returning.c_customer_sk
   JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
   JOIN store_sales ss ON ss.ss_sold_date_sk = d_cs_sold.d_date_sk
   JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
   JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
   JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
   JOIN web_page wp ON wp.wp_customer_sk = c_ss.c_customer_sk
   JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
   JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
   GROUP BY d_cs_sold.d_year, p_ss.p_promo_name
   HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
   year,
   promo_name,
   total_store_profit,
   total_catalog_paid,
   total_return_loss,
   profit_flag,
   distinct_store_customers,
   RANK() OVER (ORDER BY total_store_profit DESC) AS profit_rank,
   SUM(total_store_profit) OVER (ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_year
FROM agg
ORDER BY total_store_profit DESC
LIMIT 100
