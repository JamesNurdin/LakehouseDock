WITH sales_by_state AS (
   SELECT
      ca.ca_state,
      d.d_year,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2002
   GROUP BY ca.ca_state, d.d_year
),
promo_sales AS (
   SELECT
      ca.ca_state,
      d.d_year,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
   FROM store_sales ss
   FULL OUTER JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   WHERE p.p_channel_email = 'Y' AND d.d_year = 2002
   GROUP BY ca.ca_state, d.d_year
)
SELECT
   sales_by_state.ca_state,
   sales_by_state.d_year,
   sales_by_state.total_net_paid,
   sales_by_state.sales_cnt
FROM sales_by_state
UNION ALL
SELECT
   promo_sales.ca_state,
   promo_sales.d_year,
   promo_sales.total_net_paid,
   promo_sales.sales_cnt
FROM promo_sales
ORDER BY total_net_paid DESC
LIMIT 100
