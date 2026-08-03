WITH unified_sales AS (
    SELECT
        p.p_promo_name AS promo_name,
        td.t_hour AS hour,
        cd.cd_gender AS gender,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 100000
      AND td.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
    UNION ALL
    SELECT
        p.p_promo_name AS promo_name,
        td.t_hour AS hour,
        cd.cd_gender AS gender,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound <= 80000
      AND td.t_hour >= 18
      AND cd.cd_gender = 'F'
)
SELECT
    promo_name,
    hour,
    gender,
    SUM(net_paid) AS total_net_paid
FROM unified_sales
GROUP BY CUBE(promo_name, hour, gender)
ORDER BY total_net_paid DESC
LIMIT 100
