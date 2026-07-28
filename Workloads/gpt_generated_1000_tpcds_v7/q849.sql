WITH base AS (
   SELECT
       td.t_hour,
       cc.cc_state,
       cc.cc_name,
       r.r_reason_desc,
       sr.sr_net_loss,
       ws.ws_net_paid_inc_ship,
       sr.sr_ticket_number
   FROM tpcds.time_dim td
   JOIN tpcds.store_returns sr
     ON sr.sr_return_time_sk = td.t_time_sk
   JOIN tpcds.customer_demographics cd
     ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.household_demographics hd
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   JOIN tpcds.catalog_returns cr
     ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN tpcds.call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.web_sales ws
     ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 8 AND 18
     AND sr.sr_return_tax > 10
     AND cr.cr_store_credit < 500
     AND ws.ws_net_paid_inc_ship > 1000
     AND cc.cc_state = 'CA'
     AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
   t_hour,
   cc_state,
   cc_name,
   SUM(sr_net_loss) AS total_net_loss,
   SUM(ws_net_paid_inc_ship) AS total_sales,
   COUNT(DISTINCT sr_ticket_number) AS distinct_returns,
   RANK() OVER (PARTITION BY t_hour ORDER BY SUM(sr_net_loss) DESC) AS loss_rank
FROM base
GROUP BY t_hour, cc_state, cc_name
ORDER BY t_hour, loss_rank
