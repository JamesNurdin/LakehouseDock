WITH unified_sales AS (
 SELECT
   cs.cs_sold_date_sk AS date_sk,
   cs.cs_item_sk AS item_sk,
   cs.cs_call_center_sk AS location_sk,
   cs.cs_quantity AS quantity,
   cs.cs_net_paid AS net_paid,
   'Catalog' AS channel,
   cc.cc_state AS state,
   p.p_promo_id AS promo_id
 FROM catalog_sales cs
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 UNION ALL
 SELECT
   ss.ss_sold_date_sk,
   ss.ss_item_sk,
   ss.ss_store_sk,
   ss.ss_quantity,
   ss.ss_net_paid,
   'Store' AS channel,
   s.s_state AS state,
   p.p_promo_id
 FROM store_sales ss
 LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 UNION ALL
 SELECT
   ws.ws_sold_date_sk,
   ws.ws_item_sk,
   ws.ws_web_site_sk,
   ws.ws_quantity,
   ws.ws_net_paid,
   'Web' AS channel,
   ws_site.web_state AS state,
   p.p_promo_id
 FROM web_sales ws
 LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
monthly_sales AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   us.channel,
   us.state,
   i.i_brand,
   i.i_category,
   SUM(us.net_paid) AS monthly_net_paid,
   SUM(us.quantity) AS monthly_quantity,
   SUM(CASE WHEN us.promo_id IS NOT NULL THEN us.net_paid ELSE 0 END) AS promo_net_paid
 FROM unified_sales us
 JOIN date_dim d ON us.date_sk = d.d_date_sk
 JOIN item i ON us.item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
   AND us.state IS NOT NULL
 GROUP BY d.d_year, d.d_month_seq, us.channel, us.state, i.i_brand, i.i_category
 HAVING SUM(us.net_paid) > 50000
)
SELECT
   ms.d_year,
   ms.d_month_seq,
   ms.channel,
   ms.state,
   ms.i_brand,
   ms.i_category,
   ms.monthly_quantity,
   ROUND(ms.monthly_net_paid, 2) AS monthly_net_paid,
   ms.promo_net_paid,
   SUM(ms.monthly_net_paid) OVER (
     PARTITION BY ms.channel, ms.state, ms.i_brand, ms.i_category
     ORDER BY ms.d_year, ms.d_month_seq
     ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
   ) AS prior_two_months_net,
   RANK() OVER (
     PARTITION BY ms.d_year, ms.channel
     ORDER BY ms.monthly_net_paid DESC
   ) AS revenue_rank
FROM monthly_sales ms
ORDER BY ms.d_year, ms.d_month_seq, ms.channel, ms.monthly_net_paid DESC
