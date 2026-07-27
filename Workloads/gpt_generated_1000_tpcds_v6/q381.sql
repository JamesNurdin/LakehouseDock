WITH sales_returns_a AS (
   SELECT
       i.i_category,
       r.r_reason_desc,
       hd.hd_buy_potential,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(sr.sr_return_amt_inc_tax) AS total_returns,
       COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
       AVG(ss.ss_net_profit) AS avg_profit,
       MIN(sr.sr_fee) AS min_fee,
       MAX(sr.sr_fee) AS max_fee
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE i.i_manufact = 'barcallyese'
     AND c.c_birth_day = 7
     AND sr.sr_return_amt_inc_tax > 1000
     AND wp.wp_type = 'article'
     AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
   GROUP BY i.i_category, r.r_reason_desc, hd.hd_buy_potential
),
sales_returns_b AS (
   SELECT
       i.i_category,
       r.r_reason_desc,
       hd.hd_buy_potential,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(sr.sr_return_amt_inc_tax) AS total_returns,
       COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
       AVG(ss.ss_net_profit) AS avg_profit,
       MIN(sr.sr_fee) AS min_fee,
       MAX(sr.sr_fee) AS max_fee
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE i.i_manufact = 'ableanti'
     AND c.c_birth_day = 22
     AND sr.sr_return_amt_inc_tax < 200
     AND wp.wp_type = 'home'
     AND ss.ss_sold_date_sk BETWEEN 2450200 AND 2450300
   GROUP BY i.i_category, r.r_reason_desc, hd.hd_buy_potential
)
SELECT *
FROM (
   SELECT * FROM sales_returns_a
   UNION ALL
   SELECT * FROM sales_returns_b
) combined
ORDER BY i_category, r_reason_desc, total_sales DESC
LIMIT 100
