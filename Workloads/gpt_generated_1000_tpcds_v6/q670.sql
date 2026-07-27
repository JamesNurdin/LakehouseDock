WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_sold_time_sk,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_ext_tax > 20
      AND ws.ws_quantity >= 2
      AND cd.cd_gender = 'F'
      AND sm.sm_carrier = 'UPS'
      AND w.web_manager = 'Tommy Jones'
      AND td.t_hour BETWEEN 9 AND 17
      AND ws.ws_net_profit > 0
),
agg_sales AS (
    SELECT
        w.web_name,
        w.web_manager,
        sm.sm_carrier,
        cd.cd_gender,
        td.t_hour,
        SUM(fs.ws_net_profit) AS total_net_profit
    FROM filtered_sales fs
    JOIN web_site w ON fs.ws_web_site_sk = w.web_site_sk
    JOIN ship_mode sm ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON fs.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON fs.ws_sold_time_sk = td.t_time_sk
    GROUP BY w.web_name, w.web_manager, sm.sm_carrier, cd.cd_gender, td.t_hour
)
SELECT
    web_name,
    web_manager,
    sm_carrier,
    cd_gender,
    t_hour,
    total_net_profit,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY profit_rank ASC
LIMIT 100
