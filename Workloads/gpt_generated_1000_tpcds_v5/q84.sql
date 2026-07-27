WITH filtered_sales AS (
   SELECT ss.ss_sold_date_sk,
          ss.ss_ticket_number,
          ss.ss_item_sk,
          ss.ss_promo_sk,
          ss.ss_quantity,
          ss.ss_net_paid,
          ss.ss_net_profit,
          ss.ss_store_sk
   FROM store_sales ss
   WHERE ss.ss_quantity > 1
     AND ss.ss_net_paid > 0
),
filtered_web AS (
   SELECT ws.ws_order_number,
          ws.ws_promo_sk,
          ws.ws_quantity,
          ws.ws_net_paid,
          ws.ws_ship_mode_sk,
          ws.ws_web_site_sk
   FROM web_sales ws
   WHERE ws.ws_quantity > 0
     AND ws.ws_net_paid > 0
)
SELECT p.p_promo_name,
       ws_site.web_company_name,
       r.r_reason_desc,
       sm.sm_type,
       SUM(fs.ss_net_paid) AS total_store_sales,
       SUM(fw.ws_net_paid) AS total_web_sales,
       COUNT(DISTINCT fs.ss_ticket_number) AS distinct_store_tickets,
       AVG(sr.sr_return_amt) AS avg_return_amount,
       MIN(p.p_cost) AS min_promo_cost,
       MAX(sm.sm_code) AS max_ship_mode_code
FROM filtered_sales fs
JOIN store_returns sr
     ON sr.sr_ticket_number = fs.ss_ticket_number
    AND sr.sr_item_sk = fs.ss_item_sk
JOIN promotion p
     ON fs.ss_promo_sk = p.p_promo_sk
JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
JOIN filtered_web fw
     ON fw.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
     ON fw.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws_site
     ON fw.ws_web_site_sk = ws_site.web_site_sk
WHERE p.p_channel_demo = 'N'
  AND p.p_channel_email = 'Y'
  AND p.p_start_date_sk BETWEEN 2450316 AND 2450633
  AND r.r_reason_id = 'AAAAAAAADBAAAAAA'
  AND sm.sm_type = 'AIR'
  AND ws_site.web_company_name = 'ought'
  AND ws_site.web_tax_percentage >= 0.02
  AND fs.ss_net_paid > (SELECT AVG(ss_net_paid) FROM store_sales WHERE ss_quantity > 1)
GROUP BY ROLLUP (p.p_promo_name, ws_site.web_company_name, r.r_reason_desc, sm.sm_type)
HAVING SUM(fs.ss_net_paid) > 1000
ORDER BY total_store_sales DESC
LIMIT 100
