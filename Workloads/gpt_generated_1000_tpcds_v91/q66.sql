WITH agg_sales AS (
  SELECT
    s.s_store_id,
    dd.d_year,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss
  FROM store_sales ss
  JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN inventory i ON dd.d_date_sk = i.inv_date_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = dd.d_date_sk
    AND cr.cr_returned_time_sk = td.t_time_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = dd.d_date_sk
    AND ws.ws_sold_time_sk = td.t_time_sk
    AND ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = dd.d_date_sk
    AND wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  WHERE
    dd.d_year = 2001
    AND s.s_state = 'CA'
    AND ca.ca_country = 'United States'
    AND ss.ss_ticket_number NOT IN (
      SELECT sr2.sr_ticket_number
      FROM store_returns sr2
      WHERE sr2.sr_net_loss > 0
    )
  GROUP BY
    s.s_store_id,
    dd.d_year,
    p.p_promo_name
)
SELECT
  a.s_store_id,
  a.d_year,
  a.p_promo_name,
  a.total_net_profit,
  a.avg_net_profit,
  a.distinct_tickets,
  a.total_store_return_loss,
  a.total_catalog_return_loss,
  a.total_web_return_loss,
  SUM(a.total_net_profit) OVER (PARTITION BY a.s_store_id) AS store_total_net_profit,
  ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_profit DESC) AS store_profit_rank
FROM agg_sales a
ORDER BY a.total_net_profit DESC
LIMIT 100
