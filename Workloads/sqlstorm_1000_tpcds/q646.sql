WITH
 raw_sales AS (
   SELECT d.d_date,
          d.d_year,
          COUNT(DISTINCT ss.ss_customer_sk) AS store_customers,
          COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers,
          SUM(ss.ss_net_paid) AS store_net,
          SUM(ws.ws_net_paid) AS web_net,
          SUM(ss.ss_net_profit) AS store_profit,
          SUM(ws.ws_net_profit) AS web_profit
   FROM date_dim d
   LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
   GROUP BY d.d_date, d.d_year
 ),
 ds AS (
   SELECT raw_sales.*,
          ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY store_net DESC) AS store_year_rank,
          ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY web_net DESC) AS web_year_rank
   FROM raw_sales
 ),
 top_customers AS (
   SELECT
      d.d_date,
      c.c_customer_id,
      COALESCE(ss.ss_sum,0) + COALESCE(ws.ws_sum,0) AS total_sales,
      ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY COALESCE(ss.ss_sum,0) + COALESCE(ws.ws_sum,0) DESC) AS rn
   FROM date_dim d
   JOIN (SELECT DISTINCT c_customer_id, c_customer_sk FROM customer) c ON TRUE
   LEFT JOIN (
      SELECT ss_customer_sk, ss_sold_date_sk, SUM(ss_net_paid) AS ss_sum
      FROM store_sales
      GROUP BY ss_customer_sk, ss_sold_date_sk
   ) ss ON ss.ss_customer_sk = c.c_customer_sk AND ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN (
      SELECT ws_bill_customer_sk, ws_sold_date_sk, SUM(ws_net_paid) AS ws_sum
      FROM web_sales
      GROUP BY ws_bill_customer_sk, ws_sold_date_sk
   ) ws ON ws.ws_bill_customer_sk = c.c_customer_sk AND ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_date IS NOT NULL
 ),
 promotions_and_returns AS (
   SELECT
      p.p_promo_id AS promo_id,
      CASE
         WHEN p.p_discount_active = 'Y' THEN 'ACTIVE'
         WHEN p.p_discount_active IS NULL THEN 'UNKNOWN'
         ELSE 'INACTIVE'
      END AS promo_status,
      COALESCE(cr.cr_return_amount,0) - COALESCE(p.p_cost,0) AS net_promo_return
   FROM promotion p
   LEFT JOIN catalog_returns cr
       ON cr.cr_reason_sk = p.p_promo_sk
          AND cr.cr_return_quantity > 0
   WHERE p.p_start_date_sk IS NOT NULL
     AND p.p_end_date_sk IS NOT NULL
     AND (p.p_channel_email = 'Y' OR p.p_channel_tv = 'Y')
 ),
 weird_set AS (
   SELECT ca.ca_city AS key, ca.ca_state AS val FROM customer_address ca
   UNION ALL
   SELECT s.s_city, s.s_state FROM store s
   EXCEPT
   SELECT wp.wp_url, wp.wp_type FROM web_page wp WHERE wp.wp_autogen_flag = 'Y'
 ),
 correlated AS (
   SELECT
      d.d_date,
      (SELECT MAX(ss.ss_net_paid) FROM store_sales ss WHERE ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_quantity > 0) AS max_store_payment,
      (SELECT SUM(ws.ws_net_paid) FROM web_sales ws WHERE ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_quantity > 0) AS total_web_payment
   FROM date_dim d
   WHERE d.d_year = 2000
 )
SELECT
   ds.d_date,
   ds.d_year,
   ds.store_customers,
   ds.web_customers,
   ds.store_net,
   ds.web_net,
   ds.store_profit,
   ds.web_profit,
   ds.store_year_rank,
   ds.web_year_rank,
   COALESCE(tc.total_sales,0) AS top_customer_sales,
   tc.c_customer_id AS top_customer_id,
   CASE
      WHEN ds.store_net > ds.web_net THEN 'STORE_LEADS'
      WHEN ds.store_net < ds.web_net THEN 'WEB_LEADS'
      ELSE 'TIED'
   END AS sales_leader,
   pnr.promo_id,
   pnr.promo_status,
   pnr.net_promo_return,
   w.key,
   w.val,
   cor.max_store_payment,
   cor.total_web_payment,
   CASE
      WHEN cor.max_store_payment IS NULL THEN 'NO_STORE_SALES'
      WHEN cor.total_web_payment = 0 THEN 'NO_WEB_SALES'
      ELSE CAST(cor.max_store_payment / cor.total_web_payment AS varchar)
   END AS store_to_web_ratio
FROM ds
LEFT JOIN (SELECT * FROM top_customers WHERE rn = 1) tc
   ON tc.d_date = ds.d_date
LEFT JOIN promotions_and_returns pnr
   ON pnr.promo_id = (SELECT p.p_promo_id FROM promotion p ORDER BY random() LIMIT 1)
LEFT JOIN weird_set w
   ON w.key = CAST(ds.d_date AS varchar)
LEFT JOIN correlated cor
   ON cor.d_date = ds.d_date
WHERE ds.store_year_rank <= 5
   AND (ds.web_customers IS NOT NULL OR ds.store_customers IS NOT NULL)
   AND (ds.store_net + ds.web_net) IS NOT DISTINCT FROM (ds.store_net + ds.web_net)
ORDER BY ds.d_date DESC
LIMIT 100
