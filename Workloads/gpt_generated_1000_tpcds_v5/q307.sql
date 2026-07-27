WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_hdemo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_tax) AS avg_tax,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code IN ('AIR', 'SEA', 'SURFACE')
      AND ws.ws_sales_price > 20.00
      AND s.web_state = 'CA'
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_mode_sk, ws.ws_bill_hdemo_sk
)
SELECT
    s.web_name,
    sm.sm_carrier,
    agg.total_sales,
    agg.total_profit,
    agg.order_cnt,
    RANK() OVER (PARTITION BY s.web_name ORDER BY agg.total_profit DESC) AS profit_rank,
    CASE
        WHEN agg.total_profit > 10000 THEN 'HIGH'
        WHEN agg.total_profit > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM sales_agg agg
JOIN web_site s ON agg.ws_web_site_sk = s.web_site_sk
JOIN ship_mode sm ON agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY profit_rank, agg.total_sales DESC
LIMIT 100
