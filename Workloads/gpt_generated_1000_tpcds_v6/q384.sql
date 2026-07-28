WITH
  /* Store channel – sales and returns */
  store_data AS (
    SELECT
      s.s_store_name AS store_name,
      td.t_hour AS hour,
      SUM(ss.ss_net_paid) AS total_sales,
      SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns,
      COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
      COALESCE(r.r_reason_desc, 'No Return') AS return_reason
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY s.s_store_name, td.t_hour, r.r_reason_desc
  ),

  /* Web channel – sales and returns */
  web_data AS (
    SELECT
      wsite.web_name AS web_name,
      td2.t_hour AS hour,
      SUM(ws.ws_net_paid) AS total_sales,
      SUM(COALESCE(wr.wr_net_loss, 0)) AS total_returns,
      COUNT(DISTINCT ws.ws_order_number) AS num_transactions,
      COALESCE(r2.r_reason_desc, 'No Return') AS return_reason
    FROM web_sales ws
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN time_dim td2
      ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN customer_address ca2
      ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    JOIN customer_demographics cd2
      ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r2
      ON wr.wr_reason_sk = r2.r_reason_sk
    GROUP BY wsite.web_name, td2.t_hour, r2.r_reason_desc
  ),

  /* Catalog channel – sales and returns */
  catalog_data AS (
    SELECT
      cp.cp_catalog_page_id AS catalog_page_id,
      td3.t_hour AS hour,
      SUM(cs.cs_net_paid) AS total_sales,
      SUM(COALESCE(cr.cr_net_loss, 0)) AS total_returns,
      COUNT(DISTINCT cs.cs_order_number) AS num_transactions,
      COALESCE(r3.r_reason_desc, 'No Return') AS return_reason
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td3
      ON cs.cs_sold_time_sk = td3.t_time_sk
    JOIN customer_address ca3
      ON cs.cs_bill_addr_sk = ca3.ca_address_sk
    JOIN customer_demographics cd3
      ON cs.cs_bill_cdemo_sk = cd3.cd_demo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r3
      ON cr.cr_reason_sk = r3.r_reason_sk
    GROUP BY cp.cp_catalog_page_id, td3.t_hour, r3.r_reason_desc
  )

SELECT
  channel,
  hour,
  SUM(total_sales) AS agg_sales,
  SUM(total_returns) AS agg_returns,
  SUM(num_transactions) AS agg_transactions
FROM (
  SELECT 'Store'    AS channel, store_name    AS entity, hour, total_sales, total_returns, num_transactions, return_reason FROM store_data
  UNION ALL
  SELECT 'Web'      AS channel, web_name      AS entity, hour, total_sales, total_returns, num_transactions, return_reason FROM web_data
  UNION ALL
  SELECT 'Catalog'  AS channel, catalog_page_id AS entity, hour, total_sales, total_returns, num_transactions, return_reason FROM catalog_data
) AS combined
GROUP BY channel, hour
ORDER BY channel, hour
