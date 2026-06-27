WITH
  /* Aggregate store sales by hour */
  store_sales_agg AS (
    SELECT
      td.t_hour AS hour,
      SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
  ),
  /* Aggregate store returns by hour */
  store_returns_agg AS (
    SELECT
      td.t_hour AS hour,
      SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    GROUP BY td.t_hour
  ),
  /* Aggregate catalog sales by hour */
  catalog_sales_agg AS (
    SELECT
      td.t_hour AS hour,
      SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
  ),
  /* Aggregate catalog returns by hour */
  catalog_returns_agg AS (
    SELECT
      td.t_hour AS hour,
      SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_hour
  ),
  /* Aggregate web sales by hour */
  web_sales_agg AS (
    SELECT
      td.t_hour AS hour,
      SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
  ),
  /* Aggregate web returns by hour */
  web_returns_agg AS (
    SELECT
      td.t_hour AS hour,
      SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_hour
  ),
  /* Combine store sales & returns */
  store_combined AS (
    SELECT
      COALESCE(s.hour, r.hour) AS hour,
      COALESCE(s.total_net_profit, 0) AS total_net_profit,
      COALESCE(r.total_net_loss, 0) AS total_net_loss,
      COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0) AS net_contribution
    FROM store_sales_agg s
    FULL OUTER JOIN store_returns_agg r ON s.hour = r.hour
  ),
  /* Combine catalog sales & returns */
  catalog_combined AS (
    SELECT
      COALESCE(s.hour, r.hour) AS hour,
      COALESCE(s.total_net_profit, 0) AS total_net_profit,
      COALESCE(r.total_net_loss, 0) AS total_net_loss,
      COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0) AS net_contribution
    FROM catalog_sales_agg s
    FULL OUTER JOIN catalog_returns_agg r ON s.hour = r.hour
  ),
  /* Combine web sales & returns */
  web_combined AS (
    SELECT
      COALESCE(s.hour, r.hour) AS hour,
      COALESCE(s.total_net_profit, 0) AS total_net_profit,
      COALESCE(r.total_net_loss, 0) AS total_net_loss,
      COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0) AS net_contribution
    FROM web_sales_agg s
    FULL OUTER JOIN web_returns_agg r ON s.hour = r.hour
  )
SELECT
  'store'   AS channel,
  hour,
  total_net_profit,
  total_net_loss,
  net_contribution
FROM store_combined
UNION ALL
SELECT
  'catalog' AS channel,
  hour,
  total_net_profit,
  total_net_loss,
  net_contribution
FROM catalog_combined
UNION ALL
SELECT
  'web'     AS channel,
  hour,
  total_net_profit,
  total_net_loss,
  net_contribution
FROM web_combined
ORDER BY channel, hour
