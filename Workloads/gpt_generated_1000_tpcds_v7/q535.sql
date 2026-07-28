WITH ss_agg AS (
   SELECT
      ss_item_sk,
      ss_sold_time_sk,
      SUM(ss_net_paid)        AS sum_net_paid,
      SUM(ss_net_profit)      AS sum_net_profit,
      COUNT(*)                AS cnt_sales
   FROM store_sales
   GROUP BY ss_item_sk, ss_sold_time_sk
),
cs_agg AS (
   SELECT
      cs_item_sk,
      cs_sold_time_sk,
      SUM(cs_net_paid)        AS cs_sum_net_paid,
      SUM(cs_net_profit)      AS cs_sum_net_profit
   FROM catalog_sales
   GROUP BY cs_item_sk, cs_sold_time_sk
),
ws_agg AS (
   SELECT
      ws_item_sk,
      ws_sold_time_sk,
      SUM(ws_net_paid)        AS ws_sum_net_paid,
      SUM(ws_net_profit)      AS ws_sum_net_profit
   FROM web_sales
   GROUP BY ws_item_sk, ws_sold_time_sk
)
SELECT
   i.i_item_id,
   i.i_category,
   t.t_hour,
   ss.sum_net_paid                               AS store_net_paid,
   cs.cs_sum_net_paid                            AS catalog_net_paid,
   ws.ws_sum_net_paid                            AS web_net_paid,
   (ss.sum_net_paid + cs.cs_sum_net_paid + ws.ws_sum_net_paid) AS total_net_paid,
   (ss.sum_net_profit + cs.cs_sum_net_profit + ws.ws_sum_net_profit) AS total_net_profit,
   cc.cc_name                                    AS call_center_name,
   cp.cp_department                              AS catalog_department,
   sm.sm_type                                    AS ship_mode_type,
   ws_site.web_name                              AS website_name
FROM ss_agg ss
JOIN store_sales ss_raw
  ON ss_raw.ss_item_sk = ss.ss_item_sk
 AND ss_raw.ss_sold_time_sk = ss.ss_sold_time_sk
JOIN time_dim t
  ON t.t_time_sk = ss.ss_sold_time_sk
JOIN item i
  ON i.i_item_sk = ss.ss_item_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = ss_raw.ss_cdemo_sk
JOIN customer_address ca
  ON ca.ca_address_sk = ss_raw.ss_addr_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss_raw.ss_ticket_number
JOIN catalog_sales cs_raw
  ON cs_raw.cs_item_sk = i.i_item_sk
 AND cs_raw.cs_sold_time_sk = t.t_time_sk
JOIN cs_agg cs
  ON cs.cs_item_sk = i.i_item_sk
 AND cs.cs_sold_time_sk = t.t_time_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_order_number = cs_raw.cs_order_number
JOIN call_center cc
  ON cc.cc_call_center_sk = cs_raw.cs_call_center_sk
JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cs_raw.cs_catalog_page_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cs_raw.cs_ship_mode_sk
JOIN promotion p
  ON p.p_promo_sk = cs_raw.cs_promo_sk
JOIN web_sales ws_raw
  ON ws_raw.ws_item_sk = i.i_item_sk
 AND ws_raw.ws_sold_time_sk = t.t_time_sk
JOIN ws_agg ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site ws_site
  ON ws_site.web_site_sk = ws_raw.ws_web_site_sk
WHERE
   t.t_hour BETWEEN 10 AND 15
   AND cd.cd_credit_rating = 'Good'
   AND i.i_category = 'Sports'
GROUP BY
   i.i_item_id,
   i.i_category,
   t.t_hour,
   ss.sum_net_paid,
   cs.cs_sum_net_paid,
   ws.ws_sum_net_paid,
   ss.sum_net_profit,
   cs.cs_sum_net_profit,
   ws.ws_sum_net_profit,
   cc.cc_name,
   cp.cp_department,
   sm.sm_type,
   ws_site.web_name
ORDER BY total_net_paid DESC
LIMIT 100
