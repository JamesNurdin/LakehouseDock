WITH
  store_combined AS (
    SELECT
      d.d_year,
      s.s_store_id AS entity_id,
      SUM(COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_sales,
      SUM(COALESCE(sr.sr_net_loss, 0))      AS total_returns,
      CASE WHEN SUM(COALESCE(ss.ss_net_profit, 0)) - SUM(COALESCE(sr.sr_net_loss, 0)) > 0
           THEN 'Profitable'
           ELSE 'Loss'
      END AS profit_status
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d
      ON COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk) = d.d_date_sk
    LEFT JOIN store s
      ON COALESCE(ss.ss_store_sk, sr.sr_store_sk) = s.s_store_sk
    WHERE EXISTS (
      SELECT 1
      FROM item i
      WHERE i.i_item_sk = COALESCE(ss.ss_item_sk, sr.sr_item_sk)
        AND i.i_brand = 'Brand#12'
    )
    GROUP BY d.d_year, s.s_store_id
  ),

  web_agg AS (
    SELECT
      d.d_year,
      'WEB' AS entity_id,
      SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
      0                                        AS total_returns,
      CASE WHEN SUM(ws.ws_net_paid_inc_ship_tax) > 100000
           THEN 'High'
           ELSE 'Low'
      END AS profit_status,
      'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_ship_mode_sk IN (
      SELECT sm.sm_ship_mode_sk
      FROM ship_mode sm
      WHERE sm.sm_type = 'AIR'
    )
    GROUP BY d.d_year
  ),

  unioned AS (
    SELECT d_year, entity_id, total_sales, total_returns, profit_status, 'Store' AS channel
    FROM store_combined
    UNION ALL
    SELECT d_year, entity_id, total_sales, total_returns, profit_status, channel
    FROM web_agg
  ),

  ranked AS (
    SELECT
      d_year,
      entity_id,
      total_sales,
      total_returns,
      profit_status,
      channel,
      row_number() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS rn
    FROM unioned
  )
SELECT
  d_year,
  entity_id,
  total_sales,
  total_returns,
  profit_status,
  channel
FROM ranked
WHERE rn <= 5
ORDER BY channel, total_sales DESC
LIMIT 100
