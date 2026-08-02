WITH
  store_agg AS (
    SELECT
      r.r_reason_id,
      t.t_hour,
      SUM(sr.sr_net_loss) AS store_net_loss,
      COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc LIKE '%price%'
      AND t.t_hour BETWEEN 10 AND 20
      AND ca.ca_gmt_offset = -6.00
      AND s.s_gmt_offset = -5.00
    GROUP BY ROLLUP (r.r_reason_id, t.t_hour)
  ),
  web_agg AS (
    SELECT
      r.r_reason_id,
      t.t_hour,
      ws.ws_ship_mode_sk,
      SUM(wr.wr_net_loss) AS web_net_loss,
      COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE r.r_reason_desc LIKE '%price%'
      AND t.t_hour BETWEEN 10 AND 20
      AND ca_ref.ca_gmt_offset = -6.00
      AND ca_ret.ca_gmt_offset = -6.00
    GROUP BY CUBE (r.r_reason_id, t.t_hour, ws.ws_ship_mode_sk)
  ),
  combined AS (
    SELECT
      'store' AS source,
      r_reason_id,
      t_hour,
      store_net_loss AS net_loss,
      store_return_cnt AS cnt
    FROM store_agg
    UNION ALL
    SELECT
      'web' AS source,
      r_reason_id,
      t_hour,
      web_net_loss AS net_loss,
      web_return_cnt AS cnt
    FROM web_agg
  ),
  crossed AS (
    SELECT c.*, d.cat
    FROM combined c
    CROSS JOIN (SELECT 'X' AS cat UNION ALL SELECT 'Y' AS cat) d
  ),
  grp AS (
    SELECT
      source,
      r_reason_id,
      cat,
      SUM(net_loss) AS total_net_loss,
      SUM(cnt) AS total_cnt
    FROM crossed
    WHERE net_loss > 0
      AND cat = 'X'
      AND source IS NOT NULL
    GROUP BY ROLLUP (source, r_reason_id, cat)
    HAVING SUM(cnt) > 0
       AND SUM(net_loss) > 100
  )
SELECT
  source,
  r_reason_id,
  cat,
  total_net_loss,
  total_cnt,
  AVG(total_net_loss) OVER (PARTITION BY r_reason_id) AS avg_total_net_loss_by_reason
FROM grp
ORDER BY source, r_reason_id, cat
