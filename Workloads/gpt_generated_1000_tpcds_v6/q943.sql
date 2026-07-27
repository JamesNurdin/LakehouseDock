WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        p.p_channel_email,
        sm.sm_code,
        wsite.web_name,
        wsite.web_site_id,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT
    sr.web_name AS site_name,
    sr.sm_code AS ship_mode,
    SUM(sr.ws_net_profit) AS total_profit,
    SUM(sr.ws_net_paid) AS total_paid,
    COUNT(DISTINCT sr.ws_order_number) AS order_cnt,
    'Sales_Email_Air' AS src
FROM sales_returns sr
WHERE sr.p_channel_email = 'Y'
  AND sr.sm_code = 'AIR'
GROUP BY sr.web_name, sr.sm_code

UNION ALL

SELECT
    sr.web_name AS site_name,
    sr.sm_code AS ship_mode,
    SUM(sr.wr_net_loss) AS total_profit,
    CAST(NULL AS decimal(7,2)) AS total_paid,
    COUNT(DISTINCT sr.ws_order_number) AS order_cnt,
    'Returns_NonEmail_Surface' AS src
FROM sales_returns sr
WHERE sr.p_channel_email = 'N'
  AND sr.sm_code = 'SURFACE'
  AND sr.wr_order_number IS NOT NULL
GROUP BY sr.web_name, sr.sm_code

ORDER BY site_name, ship_mode, src
LIMIT 100
