WITH customer_income AS (
   SELECT c.c_customer_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound
   FROM customer c
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_lower_bound >= 50000
)
SELECT entity_id,
       entity_name,
       profit,
       channel
FROM (
   SELECT s.s_store_sk AS entity_sk,
          s.s_store_id AS entity_id,
          s.s_store_name AS entity_name,
          SUM(ss.ss_net_profit) AS profit,
          'Store' AS channel
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_income ci ON ss.ss_customer_sk = ci.c_customer_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451053
   GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name

   UNION ALL

   SELECT wsite.web_site_sk AS entity_sk,
          wsite.web_site_id AS entity_id,
          wsite.web_name AS entity_name,
          SUM(ws.ws_net_profit) AS profit,
          'Web' AS channel
   FROM web_sales ws
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN customer_income ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451053
   GROUP BY wsite.web_site_sk, wsite.web_site_id, wsite.web_name
) AS combined
WHERE (combined.channel = 'Store' AND EXISTS (
          SELECT 1 FROM store_sales ss2
          WHERE ss2.ss_store_sk = combined.entity_sk
            AND ss2.ss_promo_sk IS NOT NULL
        ))
   OR (combined.channel = 'Web' AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_web_site_sk = combined.entity_sk
            AND ws2.ws_promo_sk IS NOT NULL
        ))
ORDER BY profit DESC
LIMIT 100
