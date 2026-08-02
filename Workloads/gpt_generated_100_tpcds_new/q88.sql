WITH
  -- Base join that includes every table, using a FULL OUTER JOIN between store and date_dim
  base AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      cc.cc_call_center_sk,
      cc.cc_name AS call_center_name,
      d.d_date,
      d.d_year,
      t.t_time,
      ss.ss_quantity,
      ss.ss_net_profit,
      sr.sr_return_quantity,
      sr.sr_net_loss,
      r.r_reason_desc,
      ws.ws_quantity AS ws_quantity,
      ws.ws_net_profit AS ws_net_profit,
      sm.sm_type,
      w.w_warehouse_name,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      r2.r_reason_desc AS web_return_reason_desc
    FROM store s
    FULL OUTER JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store_sales ss
      ON ss.ss_store_sk = s.s_store_sk
     AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
      ON sr.sr_store_sk = s.s_store_sk
     AND sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r2
      ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc NOT LIKE '%size%'
      AND cc.cc_gmt_offset > -5
  ),
  -- First level aggregation per store
  agg_store AS (
    SELECT
      s_store_sk,
      s_store_name,
      s_state,
      SUM(ss_net_profit)               AS store_net_profit,
      SUM(ws_net_profit)               AS web_net_profit,
      SUM(sr_net_loss)                 AS store_return_loss,
      SUM(wr_net_loss)                 AS web_return_loss,
      COUNT(DISTINCT ss_quantity)      AS order_cnt
    FROM base
    GROUP BY s_store_sk, s_store_name, s_state
  ),
  -- Second level aggregation per state (average total profit)
  agg_state AS (
    SELECT
      s_state,
      AVG(store_net_profit + web_net_profit) AS avg_total_profit
    FROM agg_store
    GROUP BY s_state
    HAVING AVG(store_net_profit + web_net_profit) > 10000
  ),
  -- Add ranking per state and keep only top‑3 stores per state
  ranked AS (
    SELECT
      a.s_store_sk,
      a.s_store_name,
      a.s_state,
      a.store_net_profit,
      a.web_net_profit,
      a.store_return_loss,
      a.web_return_loss,
      a.order_cnt,
      ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY (a.store_net_profit + a.web_net_profit) DESC) AS rn
    FROM agg_store a
    JOIN agg_state s ON a.s_state = s.s_state
    WHERE EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_store_sk = a.s_store_sk
        AND sr2.sr_net_loss > 0
    )
  )
SELECT
  s_store_sk,
  s_store_name,
  s_state,
  store_net_profit,
  web_net_profit,
  store_return_loss,
  web_return_loss,
  order_cnt
FROM ranked
WHERE rn <= 3
ORDER BY s_state, rn
LIMIT 100
