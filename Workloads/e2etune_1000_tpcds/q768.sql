WITH
store_agg AS (
    SELECT
        td.t_shift,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        AVG(ss.ss_quantity) AS avg_store_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 21
      AND hd.hd_income_band_sk IN (3, 4, 5)
      AND hd.hd_buy_potential = '1001-5000'
      AND ss.ss_net_profit > 0
    GROUP BY td.t_shift, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        td.t_shift,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        AVG(ws.ws_quantity) AS avg_web_quantity
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 21
      AND hd.hd_income_band_sk IN (3, 4, 5)
      AND hd.hd_buy_potential = '1001-5000'
      AND ws.ws_net_profit > 0
    GROUP BY td.t_shift, hd.hd_income_band_sk
)
SELECT
    s.t_shift,
    s.hd_income_band_sk,
    s.store_net_profit,
    w.web_net_profit,
    s.store_txns,
    w.web_orders,
    (s.store_net_profit + w.web_net_profit) AS total_net_profit,
    CASE WHEN (s.store_txns + w.web_orders) > 0
         THEN (s.store_net_profit + w.web_net_profit) / (s.store_txns + w.web_orders)
         ELSE NULL
    END AS avg_profit_per_transaction,
    ROUND(100.0 * s.store_net_profit / NULLIF(s.store_net_profit + w.web_net_profit, 0), 2) AS store_profit_pct,
    RANK() OVER (ORDER BY (s.store_net_profit + w.web_net_profit) DESC) AS profit_rank
FROM store_agg s
JOIN web_agg w
  ON s.t_shift = w.t_shift
 AND s.hd_income_band_sk = w.hd_income_band_sk
WHERE (s.store_net_profit + w.web_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 50
