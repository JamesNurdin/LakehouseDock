WITH hd_ss AS (
   SELECT
     hd.hd_demo_sk,
     hd.hd_buy_potential,
     hd.hd_vehicle_count,
     hd.hd_dep_count,
     ss.ss_sold_date_sk,
     ss.ss_ticket_number,
     ss.ss_quantity,
     ss.ss_net_paid_inc_tax,
     ss.ss_promo_sk
   FROM household_demographics hd
   JOIN store_sales ss
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_vehicle_count >= 2
     AND hd.hd_dep_count <= 4
     AND ss.ss_quantity > 1
     AND ss.ss_net_paid_inc_tax > 500
     AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
     AND ss.ss_wholesale_cost > 10
),
promo AS (
   SELECT
     p.p_promo_sk,
     p.p_promo_name,
     p.p_cost,
     p.p_discount_active
   FROM promotion p
   WHERE p.p_cost BETWEEN 20 AND 500
     AND p.p_discount_active = 'Y'
     AND p.p_channel_email = 'Y'
     AND p.p_channel_tv = 'N'
),
hd_ss_promo AS (
   SELECT
     h.*,
     p.p_promo_name,
     p.p_cost
   FROM hd_ss h
   JOIN promo p
     ON h.ss_promo_sk = p.p_promo_sk
),
ws AS (
   SELECT
     ws.ws_bill_hdemo_sk,
     ws.ws_web_site_sk,
     ws.ws_promo_sk,
     ws.ws_net_paid_inc_tax,
     ws.ws_coupon_amt,
     ws.ws_quantity
   FROM web_sales ws
   WHERE ws.ws_net_paid_inc_tax BETWEEN 1000 AND 20000
     AND ws.ws_coupon_amt < 5000
     AND ws.ws_quantity > 1
     AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
     AND ws.ws_list_price > 50
),
ws_join AS (
   SELECT
     hsp.*,
     ws.ws_net_paid_inc_tax AS web_net_paid,
     ws.ws_coupon_amt,
     ws.ws_quantity AS web_quantity,
     ws.ws_web_site_sk
   FROM hd_ss_promo hsp
   JOIN ws
     ON ws.ws_bill_hdemo_sk = hsp.hd_demo_sk
        AND ws.ws_promo_sk = hsp.ss_promo_sk
),
final AS (
   SELECT
     wj.*, 
     wsit.web_market_manager,
     wsit.web_company_name,
     ROW_NUMBER() OVER (ORDER BY wj.ss_net_paid_inc_tax DESC) AS rn,
     CASE WHEN wj.p_cost > 100 THEN 'High' ELSE 'Low' END AS promo_cost_category
   FROM ws_join wj
   JOIN web_site wsit
     ON wj.ws_web_site_sk = wsit.web_site_sk
   WHERE wsit.web_market_manager = 'James Bernard'
     AND wsit.web_company_name LIKE 'a%'
)
SELECT
  final.web_market_manager,
  final.promo_cost_category,
  final.hd_buy_potential,
  SUM(final.ss_net_paid_inc_tax) AS total_store_sales,
  AVG(final.web_net_paid) AS avg_web_sales,
  COUNT(DISTINCT final.ss_ticket_number) AS unique_store_tickets,
  MIN(final.p_cost) AS min_promo_cost,
  MAX(final.p_cost) AS max_promo_cost,
  (SELECT MAX(p_cost) FROM promo) AS max_promo_cost_overall,
  final.rn
FROM final
GROUP BY
  final.web_market_manager,
  final.promo_cost_category,
  final.hd_buy_potential,
  final.rn
HAVING SUM(final.ss_net_paid_inc_tax) > 1000
EXCEPT
SELECT
  web_market_manager,
  promo_cost_category,
  hd_buy_potential,
  total_store_sales,
  avg_web_sales,
  unique_store_tickets,
  min_promo_cost,
  max_promo_cost,
  max_promo_cost_overall,
  rn
FROM (
  SELECT
    final.web_market_manager,
    final.promo_cost_category,
    final.hd_buy_potential,
    SUM(final.ss_net_paid_inc_tax) AS total_store_sales,
    AVG(final.web_net_paid) AS avg_web_sales,
    COUNT(DISTINCT final.ss_ticket_number) AS unique_store_tickets,
    MIN(final.p_cost) AS min_promo_cost,
    MAX(final.p_cost) AS max_promo_cost,
    (SELECT MAX(p_cost) FROM promo) AS max_promo_cost_overall,
    final.rn
  FROM final
  GROUP BY
    final.web_market_manager,
    final.promo_cost_category,
    final.hd_buy_potential,
    final.rn
  HAVING SUM(final.ss_net_paid_inc_tax) > 5000
) t
