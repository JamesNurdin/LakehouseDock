WITH sr_td AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        td.t_time,
        td.t_meal_time,
        td.t_shift
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_time = 9
      AND td.t_meal_time = 'dinner'
      AND td.t_shift = 'first'
),
sr_hd AS (
    SELECT
        sr_td.*,
        hd.hd_dep_count,
        hd.hd_income_band_sk
    FROM sr_td
    JOIN household_demographics hd
        ON sr_td.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 2
      AND hd.hd_income_band_sk IN (13, 14)
),
ws_joined AS (
    SELECT
        sr_hd.*,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk
    FROM sr_hd
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = sr_hd.sr_return_time_sk
       AND ws.ws_bill_hdemo_sk = sr_hd.sr_hdemo_sk
)
SELECT
    p.p_promo_id,
    sm.sm_carrier,
    ws_joined.hd_income_band_sk,
    ws_joined.t_meal_time,
    COUNT(DISTINCT ws_joined.ws_order_number) AS order_cnt,
    SUM(ws_joined.ws_net_paid) AS total_net_paid,
    SUM(ws_joined.sr_net_loss) AS total_net_loss,
    AVG(ws_joined.ws_ext_discount_amt) AS avg_discount
FROM ws_joined
JOIN ship_mode sm
    ON ws_joined.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON ws_joined.ws_promo_sk = p.p_promo_sk
WHERE p.p_channel_radio = 'N'
  AND p.p_response_target > 1
GROUP BY p.p_promo_id, sm.sm_carrier, ws_joined.hd_income_band_sk, ws_joined.t_meal_time
ORDER BY total_net_paid DESC
LIMIT 100
