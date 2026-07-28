WITH
  store_data AS (
    SELECT
      ss.ss_sold_date_sk AS sold_date_sk,
      s.s_store_name AS channel_name,
      ss.ss_net_paid AS net_paid,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_paid DESC) AS rn
    FROM tpcds.store_sales AS ss
    JOIN tpcds.store AS s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.time_dim AS td
      ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE s.s_state = 'CA'
  ),
  web_data AS (
    SELECT
      ws.ws_sold_date_sk AS sold_date_sk,
      we.web_name AS channel_name,
      ws.ws_net_paid AS net_paid,
      ROW_NUMBER() OVER (PARTITION BY we.web_name ORDER BY ws.ws_net_paid DESC) AS rn
    FROM tpcds.web_sales AS ws
    JOIN tpcds.web_site AS we
      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.time_dim AS td
      ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE we.web_gmt_offset = -5.00
  )
SELECT
  sold_date_sk,
  channel_name,
  net_paid,
  rn
FROM store_data
UNION ALL
SELECT
  sold_date_sk,
  channel_name,
  net_paid,
  rn
FROM web_data
ORDER BY net_paid DESC
LIMIT 100
