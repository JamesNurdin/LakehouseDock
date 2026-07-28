WITH base AS (
   SELECT
       cc.cc_name,
       p.p_promo_name,
       d.d_year,
       SUM(cs.cs_net_profit) AS total_profit,
       SUM(sr.sr_return_amt) AS total_return,
       COUNT(*) AS trans_cnt
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN catalog_sales cs ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND cc.cc_state = 'CA'
     AND sr.sr_fee > 10
     AND p.p_discount_active = 'Y'
     AND cs.cs_quantity >= 2
   GROUP BY cc.cc_name, p.p_promo_name, d.d_year
),
agg AS (
   SELECT
       p_promo_name,
       AVG(total_profit) AS avg_profit,
       SUM(total_return) AS sum_return,
       COUNT(*) AS cc_count
   FROM base
   GROUP BY p_promo_name
   HAVING AVG(total_profit) > 1000
)
SELECT
   p_promo_name,
   avg_profit,
   sum_return,
   cc_count
FROM agg
ORDER BY avg_profit DESC
LIMIT 10
