WITH store_agg AS (
       SELECT
           s.s_store_sk,
           s.s_store_id,
           s.s_state,
           s.s_market_desc,
           ss.ss_hdemo_sk,
           ss.ss_promo_sk,
           SUM(ss.ss_net_profit)                AS ss_profit,
           SUM(sr.sr_net_loss)                  AS sr_loss
       FROM store s
       JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
       JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
       GROUP BY s.s_store_sk, s.s_store_id, s.s_state, s.s_market_desc, ss.ss_hdemo_sk, ss.ss_promo_sk
   ),
   catalog_agg AS (
       SELECT
           cs.cs_bill_hdemo_sk               AS hd_demo_sk,
           SUM(cs.cs_net_paid)               AS cs_paid,
           SUM(cs.cs_ext_discount_amt)       AS cs_discount,
           AVG(cs.cs_list_price)             AS avg_list_price
       FROM catalog_sales cs
       JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
       GROUP BY cs.cs_bill_hdemo_sk
   ),
   web_agg AS (
       SELECT
           ws.ws_bill_hdemo_sk               AS hd_demo_sk,
           wp.wp_web_page_sk,
           we.web_site_sk,
           we.web_site_id,
           SUM(ws.ws_net_profit)             AS ws_profit,
           SUM(wr.wr_net_loss)               AS wr_loss
       FROM web_sales ws
       JOIN web_page wp   ON ws.ws_web_page_sk = wp.wp_web_page_sk
       JOIN web_site we   ON ws.ws_web_site_sk = we.web_site_sk
       JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_item_sk = ws.ws_item_sk
       GROUP BY ws.ws_bill_hdemo_sk, wp.wp_web_page_sk, we.web_site_sk, we.web_site_id
   )
SELECT DISTINCT
       s.s_store_id,
       s.s_state,
       s.s_market_desc,
       p.p_promo_name,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       sa.ss_profit,
       ca.cs_paid,
       wa.ws_profit,
       (sa.ss_profit + ca.cs_paid + wa.ws_profit) AS total_profit,
       RANK() OVER (PARTITION BY s.s_state ORDER BY (sa.ss_profit + ca.cs_paid + wa.ws_profit) DESC) AS state_rank
FROM   store_agg sa
JOIN   store s               ON s.s_store_sk = sa.s_store_sk
JOIN   promotion p           ON p.p_promo_sk = sa.ss_promo_sk
JOIN   household_demographics hd ON hd.hd_demo_sk = sa.ss_hdemo_sk
JOIN   income_band ib        ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN   catalog_agg ca        ON ca.hd_demo_sk = hd.hd_demo_sk
JOIN   web_agg wa            ON wa.hd_demo_sk = hd.hd_demo_sk
WHERE  s.s_state = 'CA'
  AND  ib.ib_upper_bound > 50000
  AND  p.p_discount_active = 'Y'
  AND  hd.hd_vehicle_count >= 1
  AND  s.s_gmt_offset = -5.00
  AND  EXISTS (SELECT 1
               FROM   catalog_sales cs2
               WHERE  cs2.cs_bill_hdemo_sk = hd.hd_demo_sk
                 AND  cs2.cs_list_price > 200)
ORDER BY total_profit DESC
LIMIT 100
