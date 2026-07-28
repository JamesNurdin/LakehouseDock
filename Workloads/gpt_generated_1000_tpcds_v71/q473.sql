WITH store_agg AS (
   SELECT
       ss.ss_promo_sk AS promo_sk,
       hd_store.hd_income_band_sk AS income_band_sk,
       SUM(ss.ss_net_paid) AS net_paid,
       COUNT(*) AS transactions,
       'store' AS channel
   FROM store_sales ss
   JOIN customer c_store ON ss.ss_customer_sk = c_store.c_customer_sk
   JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
   JOIN promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
   JOIN income_band ib_store ON hd_store.hd_income_band_sk = ib_store.ib_income_band_sk
   GROUP BY ss.ss_promo_sk, hd_store.hd_income_band_sk
),

catalog_agg AS (
   SELECT
       cs.cs_promo_sk AS promo_sk,
       hd_cat.hd_income_band_sk AS income_band_sk,
       SUM(cs.cs_net_paid) AS net_paid,
       COUNT(*) AS transactions,
       'catalog' AS channel
   FROM catalog_sales cs
   JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN household_demographics hd_cat ON cs.cs_bill_hdemo_sk = hd_cat.hd_demo_sk
   JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
   JOIN income_band ib_cat ON hd_cat.hd_income_band_sk = ib_cat.ib_income_band_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE EXISTS (
       SELECT 1 FROM promotion p2
       WHERE p2.p_promo_sk = cs.cs_promo_sk
         AND p2.p_discount_active = 'Y'
   )
   GROUP BY cs.cs_promo_sk, hd_cat.hd_income_band_sk
),

web_agg AS (
   SELECT
       ws.ws_promo_sk AS promo_sk,
       hd_web.hd_income_band_sk AS income_band_sk,
       SUM(ws.ws_net_paid) AS net_paid,
       COUNT(*) AS transactions,
       'web' AS channel
   FROM web_sales ws
   JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
   JOIN household_demographics hd_web ON ws.ws_bill_hdemo_sk = hd_web.hd_demo_sk
   JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   JOIN income_band ib_ws ON hd_web.hd_income_band_sk = ib_ws.ib_income_band_sk
   WHERE ws.ws_ext_ship_cost > 1000
   GROUP BY ws.ws_promo_sk, hd_web.hd_income_band_sk
),

combined AS (
   SELECT promo_sk, income_band_sk, net_paid, transactions, channel FROM store_agg
   UNION ALL
   SELECT promo_sk, income_band_sk, net_paid, transactions, channel FROM catalog_agg
   UNION ALL
   SELECT promo_sk, income_band_sk, net_paid, transactions, channel FROM web_agg
)

SELECT
   p.p_promo_id,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   combined.channel,
   SUM(combined.net_paid) AS total_net_paid,
   COUNT(*) AS rows_count
FROM combined
JOIN promotion p ON combined.promo_sk = p.p_promo_sk
JOIN income_band ib ON combined.income_band_sk = ib.ib_income_band_sk
GROUP BY
   GROUPING SETS (
      (p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound, combined.channel),
      (p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound),
      (p.p_promo_id, combined.channel),
      (p.p_promo_id),
      ()
   )
ORDER BY total_net_paid DESC
LIMIT 100
