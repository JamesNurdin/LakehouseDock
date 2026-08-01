WITH combined AS (
    SELECT
        d.d_quarter_seq AS quarter_seq,
        sm.sm_code AS ship_mode_code,
        w.w_zip AS warehouse_zip,
        SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_ext_sales_price ELSE 0 END) AS metric_sales,
        SUM(ws.ws_net_profit) AS metric_profit,
        'sales' AS record_type
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_quarter_seq = 17
      AND d.d_week_seq = 13
      AND sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
      AND w.w_zip = '46098'
      AND ws.ws_quantity > 5
      AND sr.sr_return_quantity < 3
    GROUP BY d.d_quarter_seq, sm.sm_code, w.w_zip

    UNION ALL

    SELECT
        d2.d_quarter_seq AS quarter_seq,
        sm2.sm_code AS ship_mode_code,
        w2.w_zip AS warehouse_zip,
        SUM(CASE WHEN sr.sr_return_quantity > 5 THEN sr.sr_refunded_cash ELSE 0 END) AS metric_sales,
        SUM(sr.sr_net_loss) AS metric_profit,
        'returns' AS record_type
    FROM store_returns sr
    JOIN date_dim d2
        ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN web_sales ws2
        ON ws2.ws_sold_date_sk = d2.d_date_sk
    JOIN ship_mode sm2
        ON ws2.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2
        ON ws2.ws_warehouse_sk = w2.w_warehouse_sk
    WHERE d2.d_quarter_seq = 20
      AND d2.d_week_seq = 19
      AND sm2.sm_contract = 'Ek'
      AND w2.w_zip = '56098'
      AND sr.sr_refunded_cash > 0
    GROUP BY d2.d_quarter_seq, sm2.sm_code, w2.w_zip
)
SELECT
    c.quarter_seq,
    c.ship_mode_code,
    c.warehouse_zip,
    c.metric_sales,
    c.metric_profit,
    c.record_type,
    RANK() OVER (PARTITION BY c.ship_mode_code ORDER BY c.metric_profit DESC) AS profit_rank,
    CASE WHEN c.metric_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_category,
    (SELECT AVG(c2.metric_profit) FROM combined c2 WHERE c2.ship_mode_code = c.ship_mode_code) AS avg_profit_by_ship_mode
FROM combined c
ORDER BY profit_rank, c.quarter_seq, c.ship_mode_code
LIMIT 100
