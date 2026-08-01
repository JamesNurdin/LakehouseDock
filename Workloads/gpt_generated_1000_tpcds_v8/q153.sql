WITH store_agg AS (
    SELECT
        t.t_shift AS shift,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_paid) AS total_net_paid,
        'store' AS channel
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 100000
    GROUP BY t.t_shift, cd.cd_gender
),
web_agg AS (
    SELECT
        t.t_shift AS shift,
        cd.cd_gender AS gender,
        SUM(ws.ws_net_paid) AS total_net_paid,
        'web' AS channel
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50001
    GROUP BY t.t_shift, cd.cd_gender
)
SELECT shift, gender, total_net_paid, channel
FROM store_agg
UNION ALL
SELECT shift, gender, total_net_paid, channel
FROM web_agg
ORDER BY shift, gender, channel
