WITH ss_rev AS (
 SELECT d.d_year AS sales_year,
        s.s_state AS state,
        sum(ss.ss_net_paid) AS revenue,
        count(*) AS orders,
        'store' AS channel
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
   AND p.p_discount_active = 'Y'
 GROUP BY d.d_year, s.s_state
),
ws_rev AS (
 SELECT d.d_year AS sales_year,
        ws_site.web_state AS state,
        sum(ws.ws_net_paid) AS revenue,
        count(*) AS orders,
        'web' AS channel
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
 JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
   AND p.p_discount_active = 'Y'
 GROUP BY d.d_year, ws_site.web_state
),
cs_rev AS (
 SELECT d.d_year AS sales_year,
        cc.cc_state AS state,
        sum(cs.cs_net_paid) AS revenue,
        count(*) AS orders,
        'catalog' AS channel
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
   AND p.p_discount_active = 'Y'
 GROUP BY d.d_year, cc.cc_state
)
SELECT sales_year,
       state,
       channel,
       revenue,
       orders,
       revenue / NULLIF(orders, 0) AS avg_order_value,
       row_number() OVER (PARTITION BY sales_year ORDER BY revenue DESC) AS revenue_rank
FROM (
  SELECT * FROM ss_rev
  UNION ALL
  SELECT * FROM ws_rev
  UNION ALL
  SELECT * FROM cs_rev
) t
ORDER BY sales_year, revenue_rank
