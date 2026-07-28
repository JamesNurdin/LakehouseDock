WITH max_income AS (
    SELECT MAX(ib_lower_bound) AS max_lb
    FROM income_band
)
SELECT
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    'store' AS channel,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    (SELECT max_lb FROM max_income) AS max_income_band
FROM store_sales ss
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE t.t_am_pm = 'PM'
  AND t.t_hour BETWEEN 12 AND 17
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_promo_sk = p.p_promo_sk
          AND ss2.ss_net_paid > 0
    )
GROUP BY p.p_promo_id, p.p_promo_name

UNION ALL

SELECT
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    'web' AS channel,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    (SELECT max_lb FROM max_income) AS max_income_band
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE t.t_am_pm = 'AM'
  AND t.t_hour BETWEEN 8 AND 11
  AND ws.ws_net_paid IS NOT NULL
GROUP BY p.p_promo_id, p.p_promo_name

ORDER BY promo_id, channel
