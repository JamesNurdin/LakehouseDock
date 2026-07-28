WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_ticket_number,
       ss.ss_quantity,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       p.p_promo_id,
       p.p_channel_dmail,
       sm.sm_carrier,
       sm.sm_contract,
       cd.cd_gender,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       CASE 
           WHEN ss.ss_net_profit > 100 THEN 'HIGH'
           WHEN ss.ss_net_profit > 0 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS profit_category,
       ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_net_profit DESC) AS profit_rank
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
     AND p.p_channel_dmail = 'Y'
     AND sm.sm_contract = 'Ek'
),
agg1 AS (
   SELECT
       p_promo_id,
       profit_category,
       COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
       SUM(ss_ext_sales_price) AS total_sales,
       SUM(ss_net_profit) AS total_profit,
       AVG(ss_quantity) AS avg_quantity
   FROM base
   WHERE profit_rank = 1
   GROUP BY p_promo_id, profit_category
)
SELECT
   a.p_promo_id,
   a.profit_category,
   a.distinct_tickets,
   a.total_sales,
   a.total_profit,
   a.avg_quantity,
   CASE 
       WHEN a.total_profit > (SELECT AVG(total_profit) FROM agg1) THEN 'ABOVE_AVG'
       ELSE 'BELOW_AVG'
   END AS profit_vs_average
FROM agg1 a
WHERE a.total_sales > 10000
ORDER BY a.total_profit DESC
LIMIT 100
