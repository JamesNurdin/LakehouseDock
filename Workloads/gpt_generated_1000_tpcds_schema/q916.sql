WITH
  store_agg AS (
    SELECT
      p.p_promo_id,
      p.p_channel_email,
      s.s_state AS state,
      SUM(ss.ss_net_profit) AS store_profit,
      COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_rec_start_date >= DATE '2001-01-01'
    GROUP BY p.p_promo_id, p.p_channel_email, s.s_state
  ),
  web_agg AS (
    SELECT
      p.p_promo_id,
      p.p_channel_email,
      w.web_state AS state,
      SUM(ws.ws_net_profit) AS web_profit,
      COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE w.web_open_date_sk > 0
    GROUP BY p.p_promo_id, p.p_channel_email, w.web_state
  ),
  combined AS (
    SELECT
      COALESCE(s.p_promo_id, w.p_promo_id) AS promo_id,
      COALESCE(s.p_channel_email, w.p_channel_email) AS channel_email,
      COALESCE(s.state, w.state) AS state,
      s.store_profit,
      w.web_profit
    FROM store_agg s
    FULL OUTER JOIN web_agg w
      ON s.p_promo_id = w.p_promo_id
     AND s.p_channel_email = w.p_channel_email
     AND s.state = w.state
  ),
  returns_agg AS (
    SELECT
      p.p_promo_id AS promo_id,
      p.p_channel_email AS channel_email,
      s.s_state AS state,
      SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE EXISTS (
      SELECT 1
      FROM store_sales ss2
      WHERE ss2.ss_promo_sk = p.p_promo_sk
        AND ss2.ss_quantity > 5
    )
    GROUP BY p.p_promo_id, p.p_channel_email, s.s_state
  )
SELECT
  promo_id,
  channel_email,
  state,
  SUM(store_profit) AS total_store_profit,
  SUM(web_profit) AS total_web_profit,
  SUM(return_loss) AS total_return_loss
FROM (
  SELECT promo_id, channel_email, state, store_profit, web_profit, CAST(NULL AS decimal(7,2)) AS return_loss
  FROM combined
  UNION ALL
  SELECT promo_id, channel_email, state, CAST(NULL AS decimal(7,2)) AS store_profit, CAST(NULL AS decimal(7,2)) AS web_profit, return_loss
  FROM returns_agg
) u
GROUP BY CUBE (promo_id, channel_email, state)
ORDER BY promo_id, channel_email, state
LIMIT 100
