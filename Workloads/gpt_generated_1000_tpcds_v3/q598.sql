WITH
store_agg AS (
   SELECT
       ss.ss_item_sk,
       t.t_hour,
       SUM(ss.ss_net_profit) AS store_profit,
       SUM(ss.ss_quantity) AS store_qty,
       COUNT(*) AS store_txns,
       MAX(ss.ss_ticket_number) AS max_ticket_number
   FROM store_sales ss
   JOIN time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   WHERE cd.cd_gender = 'M'
     AND cd.cd_education_status = 'College'
     AND p.p_discount_active = 'Y'
     AND t.t_hour BETWEEN 9 AND 17
   GROUP BY ss.ss_item_sk, t.t_hour
),
web_agg AS (
   SELECT
       ws.ws_item_sk,
       t.t_hour,
       SUM(ws.ws_net_profit) AS web_profit,
       SUM(ws.ws_quantity) AS web_qty,
       COUNT(*) AS web_txns,
       MAX(ws.ws_order_number) AS max_order_number,
       ws.ws_web_page_sk,
       ws.ws_web_site_sk,
       ws.ws_ship_mode_sk,
       ws.ws_promo_sk
   FROM web_sales ws
   JOIN time_dim t
     ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN customer_demographics cd_bill
     ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship
     ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
   WHERE cd_bill.cd_gender = 'M'
     AND cd_bill.cd_education_status = 'College'
     AND p.p_discount_active = 'Y'
     AND t.t_hour BETWEEN 9 AND 17
   GROUP BY ws.ws_item_sk, t.t_hour,
            ws.ws_web_page_sk, ws.ws_web_site_sk,
            ws.ws_ship_mode_sk, ws.ws_promo_sk
),
returns_agg AS (
   SELECT
       wr.wr_item_sk,
       t.t_hour,
       SUM(wr.wr_net_loss) AS total_return_loss,
       COUNT(*) AS return_cnt,
       wr.wr_reason_sk,
       wr.wr_web_page_sk
   FROM web_returns wr
   JOIN time_dim t
     ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 9 AND 17
   GROUP BY wr.wr_item_sk, t.t_hour,
            wr.wr_reason_sk, wr.wr_web_page_sk
)
SELECT
   i.i_item_id,
   agg.t_hour,
   agg.store_profit,
   agg.web_profit,
   agg.store_profit + agg.web_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
   agg.store_qty + agg.web_qty AS total_quantity,
   RANK() OVER (PARTITION BY agg.t_hour
                ORDER BY agg.store_profit + agg.web_profit - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank,
   (SELECT MAX(p2.p_cost)
      FROM promotion p2
     WHERE p2.p_item_sk = agg.item_sk) AS max_promo_cost
FROM (
   SELECT
       COALESCE(sa.ss_item_sk, wa.ws_item_sk) AS item_sk,
       COALESCE(sa.t_hour, wa.t_hour) AS t_hour,
       COALESCE(sa.store_profit, 0) AS store_profit,
       COALESCE(wa.web_profit, 0) AS web_profit,
       COALESCE(sa.store_qty, 0) AS store_qty,
       COALESCE(wa.web_qty, 0) AS web_qty,
       wa.ws_web_page_sk AS web_page_sk,
       wa.ws_web_site_sk AS web_site_sk,
       wa.ws_ship_mode_sk AS ship_mode_sk,
       wa.ws_promo_sk AS promo_sk
   FROM store_agg sa
   FULL OUTER JOIN web_agg wa
     ON sa.ss_item_sk = wa.ws_item_sk
    AND sa.t_hour = wa.t_hour
) agg
LEFT JOIN returns_agg r
  ON r.wr_item_sk = agg.item_sk
 AND r.t_hour = agg.t_hour
JOIN item i
  ON i.i_item_sk = agg.item_sk
LEFT JOIN web_page wp
  ON wp.wp_web_page_sk = agg.web_page_sk
LEFT JOIN web_site webs
  ON webs.web_site_sk = agg.web_site_sk
LEFT JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = agg.ship_mode_sk
LEFT JOIN reason rsn
  ON rsn.r_reason_sk = r.wr_reason_sk
WHERE i.i_current_price > 100
  AND webs.web_mkt_id IN (3, 4, 5)
  AND sm.sm_type = 'Air'
  AND rsn.r_reason_desc NOT LIKE '%fault%'
  AND agg.t_hour BETWEEN 9 AND 17
ORDER BY agg.t_hour, profit_rank
LIMIT 20
