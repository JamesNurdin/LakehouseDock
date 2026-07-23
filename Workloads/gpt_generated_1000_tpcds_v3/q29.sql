WITH per_store_reason AS (
   SELECT
      s.s_store_id AS store_id,
      s.s_state AS state,
      r.r_reason_desc AS reason_desc,
      ib.ib_lower_bound AS lower_income,
      ib.ib_upper_bound AS upper_income,
      SUM(ss.ss_net_profit) AS total_store_profit,
      SUM(cr.cr_net_loss) AS total_catalog_return_loss,
      SUM(sr.sr_net_loss) AS total_store_return_loss,
      SUM(ws.ws_net_profit) AS total_web_profit,
      SUM(wr.wr_net_loss) AS total_web_return_loss,
      SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss) AS overall_net_profit,
      COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
      COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
   FROM income_band ib
   JOIN household_demographics hd ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_sales ss ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON s.s_store_sk = ss.ss_store_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
   JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
   JOIN catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
   JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   WHERE
      ib.ib_upper_bound < 120000
      AND s.s_state = 'CA'
      AND wp.wp_max_ad_count >= 2
      AND s.s_rec_start_date >= DATE '2001-01-01'
   GROUP BY
      s.s_store_id,
      s.s_state,
      r.r_reason_desc,
      ib.ib_lower_bound,
      ib.ib_upper_bound
)
SELECT
   store_id,
   state,
   SUM(total_store_profit) AS total_store_profit,
   SUM(total_catalog_return_loss) AS total_catalog_return_loss,
   SUM(total_store_return_loss) AS total_store_return_loss,
   SUM(total_web_profit) AS total_web_profit,
   SUM(total_web_return_loss) AS total_web_return_loss,
   SUM(overall_net_profit) AS overall_net_profit,
   SUM(catalog_order_cnt) AS catalog_order_cnt,
   SUM(web_order_cnt) AS web_order_cnt,
   (SUM(overall_net_profit) / NULLIF(SUM(catalog_order_cnt), 0)) AS avg_profit_per_catalog_order,
   (SUM(overall_net_profit) / NULLIF(SUM(web_order_cnt), 0)) AS avg_profit_per_web_order
FROM per_store_reason
GROUP BY store_id, state
HAVING SUM(overall_net_profit) > 0
ORDER BY overall_net_profit DESC
LIMIT 100
