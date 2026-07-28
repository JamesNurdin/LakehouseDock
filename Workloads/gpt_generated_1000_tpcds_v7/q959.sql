WITH email_sales AS (
    SELECT
        sm.sm_ship_mode_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit,
        'email' AS promo_channel
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_channel_email = 'Y'
      AND d_sales.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
),

tv_sales AS (
    SELECT
        sm.sm_ship_mode_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit,
        'tv' AS promo_channel
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_channel_tv = 'Y'
      AND d_sales.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
)
SELECT
    promo_channel,
    sm_ship_mode_id,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS order_count
FROM (
    SELECT * FROM email_sales
    UNION ALL
    SELECT * FROM tv_sales
) u
GROUP BY promo_channel, sm_ship_mode_id, ib_lower_bound, ib_upper_bound
ORDER BY promo_channel, total_profit DESC
