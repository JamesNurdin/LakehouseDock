WITH ss_sample AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),
joined1 AS (
   SELECT
      s.s_store_id,
      s.s_store_name,
      c.c_customer_id,
      ss.ss_net_profit,
      sr.sr_return_amt
   FROM ss_sample ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE s.s_gmt_offset = -6.00
     AND cd.cd_credit_rating = 'Good'
     AND cp.cp_department = 'DEPARTMENT'
     AND sr.sr_return_quantity > 1
     AND cr.cr_return_amount > 100
),
joined2 AS (
   SELECT
      s.s_store_id,
      s.s_store_name,
      c.c_customer_id,
      ss.ss_net_profit,
      wr.wr_return_amt
   FROM ss_sample ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE s.s_gmt_offset = -6.00
     AND cd.cd_credit_rating = 'Good'
     AND cp.cp_department = 'DEPARTMENT'
     AND wr.wr_return_quantity > 1
     AND cr.cr_return_amount > 100
),
agg1 AS (
   SELECT
      s_store_id,
      s_store_name,
      c_customer_id,
      SUM(ss_net_profit) AS total_profit,
      SUM(sr_return_amt) AS total_return_amt
   FROM joined1
   GROUP BY s_store_id, s_store_name, c_customer_id
),
agg2 AS (
   SELECT
      s_store_id,
      s_store_name,
      c_customer_id,
      SUM(ss_net_profit) AS total_profit,
      SUM(wr_return_amt) AS total_return_amt
   FROM joined2
   GROUP BY s_store_id, s_store_name, c_customer_id
),
unioned AS (
   SELECT * FROM agg1
   UNION DISTINCT
   SELECT * FROM agg2
),
ranked AS (
   SELECT
      s_store_id,
      s_store_name,
      c_customer_id,
      total_profit,
      total_return_amt,
      CASE
         WHEN total_profit > 10000 THEN 'High'
         WHEN total_profit > 0 THEN 'Medium'
         ELSE 'Low'
      END AS profit_category,
      ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_profit DESC) AS rn,
      (SELECT AVG(total_profit) FROM unioned) AS avg_total_profit
   FROM unioned
)
SELECT
   s_store_id,
   s_store_name,
   c_customer_id,
   total_profit,
   total_return_amt,
   profit_category,
   avg_total_profit
FROM ranked
WHERE rn <= 5
ORDER BY s_store_id, rn
LIMIT 100
