WITH sampled_inv AS (
   SELECT *
   FROM inventory TABLESAMPLE BERNOULLI (10)
),
promo_array AS (
   SELECT p_promo_sk,
          ARRAY[p_promo_id, p_promo_name] AS promo_arr
   FROM promotion
),
promo_unnested AS (
   SELECT p_promo_sk, element AS promo_element
   FROM promo_array
   CROSS JOIN UNNEST(promo_arr) AS t(element)
),
base1 AS (
   SELECT
      d.d_year,
      i.i_category,
      cd.cd_gender,
      sm.sm_type,
      SUM(ss.ss_net_paid)               AS sum_store_net_paid,
      AVG(ss.ss_quantity)               AS avg_store_qty,
      COUNT(DISTINCT ss.ss_ticket_number) AS cnt_store_txn,
      SUM(cs.cs_net_paid)               AS sum_catalog_net_paid,
      SUM(ws.ws_net_paid)               AS sum_web_net_paid,
      SUM(sr.sr_net_loss)               AS sum_store_return_loss,
      SUM(wr.wr_net_loss)               AS sum_web_return_loss
   FROM store_sales ss
   FULL OUTER JOIN store_returns sr
       ON ss.ss_ticket_number = sr.sr_ticket_number
   JOIN catalog_sales cs
       ON ss.ss_item_sk = cs.cs_item_sk
   JOIN web_sales ws
       ON ss.ss_item_sk = ws.ws_item_sk
   JOIN web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
   JOIN date_dim d
       ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p_ss
       ON ss.ss_promo_sk = p_ss.p_promo_sk
   JOIN promotion p_cs
       ON cs.cs_promo_sk = p_cs.p_promo_sk
   JOIN promotion p_ws
       ON ws.ws_promo_sk = p_ws.p_promo_sk
   JOIN store s
       ON ss.ss_store_sk = s.s_store_sk
   JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca
       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
       ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN promo_unnested pu
       ON p_ss.p_promo_sk = pu.p_promo_sk
   WHERE d.d_year = 2001
     AND i.i_current_price BETWEEN 50 AND 200
     AND cc.cc_market_manager = 'John Doe'
     AND sm.sm_type = 'AIR'
   GROUP BY d.d_year, i.i_category, cd.cd_gender, sm.sm_type
),
base2 AS (
   SELECT
      d2.d_year,
      i2.i_category,
      cd2.cd_gender,
      sm2.sm_type,
      SUM(ss2.ss_net_paid)               AS sum_store_net_paid,
      AVG(ss2.ss_quantity)               AS avg_store_qty,
      COUNT(DISTINCT ss2.ss_ticket_number) AS cnt_store_txn,
      SUM(cs2.cs_net_paid)               AS sum_catalog_net_paid,
      SUM(ws2.ws_net_paid)               AS sum_web_net_paid,
      SUM(sr2.sr_net_loss)               AS sum_store_return_loss,
      SUM(wr2.wr_net_loss)               AS sum_web_return_loss
   FROM store_sales ss2
   FULL OUTER JOIN store_returns sr2
       ON ss2.ss_ticket_number = sr2.sr_ticket_number
   JOIN catalog_sales cs2
       ON ss2.ss_item_sk = cs2.cs_item_sk
   JOIN web_sales ws2
       ON ss2.ss_item_sk = ws2.ws_item_sk
   JOIN web_returns wr2
       ON ws2.ws_order_number = wr2.wr_order_number
   JOIN date_dim d2
       ON ss2.ss_sold_date_sk = d2.d_date_sk
   JOIN item i2
       ON ss2.ss_item_sk = i2.i_item_sk
   JOIN promotion p_ss2
       ON ss2.ss_promo_sk = p_ss2.p_promo_sk
   JOIN promotion p_cs2
       ON cs2.cs_promo_sk = p_cs2.p_promo_sk
   JOIN promotion p_ws2
       ON ws2.ws_promo_sk = p_ws2.p_promo_sk
   JOIN store s2
       ON ss2.ss_store_sk = s2.s_store_sk
   JOIN call_center cc2
       ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
   JOIN ship_mode sm2
       ON cs2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN customer_address ca2
       ON ss2.ss_addr_sk = ca2.ca_address_sk
   JOIN customer_demographics cd2
       ON ss2.ss_cdemo_sk = cd2.cd_demo_sk
   JOIN sampled_inv inv2
       ON ss2.ss_item_sk = inv2.inv_item_sk
   WHERE d2.d_year = 2002
     AND i2.i_current_price > 150
     AND cc2.cc_market_manager = 'Jane Smith'
     AND sm2.sm_type = 'RAIL'
   GROUP BY d2.d_year, i2.i_category, cd2.cd_gender, sm2.sm_type
)
SELECT *
FROM base1
UNION
SELECT *
FROM base2
ORDER BY d_year DESC, sum_store_net_paid DESC
LIMIT 100
