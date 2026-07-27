WITH store_agg AS (
    SELECT
        s.s_store_id,
        t.t_hour,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_channel_email = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, t.t_hour
    HAVING SUM(ss.ss_net_profit) > 10000
),
web_agg AS (
    SELECT
        ws.ws_web_site_sk,
        t.t_hour,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count
    FROM web_sales ws
    INNER JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_channel_email = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND w.w_zip = '33604'
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY ws.ws_web_site_sk, t.t_hour
    HAVING SUM(ws.ws_net_profit) > 5000
)
SELECT
    channel,
    identifier,
    period_hour,
    total_net_profit,
    txn_count,
    RANK() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        'store' AS channel,
        s_agg.s_store_id AS identifier,
        s_agg.t_hour AS period_hour,
        s_agg.total_net_profit,
        s_agg.txn_count
    FROM store_agg s_agg
    UNION ALL
    SELECT
        'web' AS channel,
        CAST(w_agg.ws_web_site_sk AS VARCHAR) AS identifier,
        w_agg.t_hour AS period_hour,
        w_agg.total_net_profit,
        w_agg.txn_count
    FROM web_agg w_agg
) combined
ORDER BY channel, profit_rank, identifier
LIMIT 100
