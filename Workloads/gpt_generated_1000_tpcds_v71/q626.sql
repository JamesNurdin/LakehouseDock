WITH agg AS (
   SELECT
       cd_bill.cd_gender AS bill_gender,
       cd_ship.cd_gender AS ship_gender,
       sm_ship2.sm_type AS ship_mode_type,
       wp.wp_type AS page_type,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(*) AS txn_count
   FROM catalog_returns cr
   JOIN customer_demographics cd_refund
       ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
   JOIN customer_demographics cd_return
       ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
   LEFT OUTER JOIN ship_mode sm_return
       ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
   JOIN ship_mode sm_main
       ON cr.cr_ship_mode_sk = sm_main.sm_ship_mode_sk
   JOIN web_sales ws
       ON ws.ws_ship_mode_sk = sm_main.sm_ship_mode_sk
   JOIN customer_demographics cd_bill
       ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship
       ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN ship_mode sm_ship2
       ON ws.ws_ship_mode_sk = sm_ship2.sm_ship_mode_sk
   JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   GROUP BY
       cd_bill.cd_gender,
       cd_ship.cd_gender,
       sm_ship2.sm_type,
       wp.wp_type
)
SELECT
   bill_gender,
   ship_gender,
   ship_mode_type,
   page_type,
   total_return_amount,
   total_net_profit,
   txn_count,
   ROW_NUMBER() OVER (PARTITION BY bill_gender ORDER BY total_return_amount DESC) AS rank_by_return
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
