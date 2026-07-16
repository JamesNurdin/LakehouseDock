WITH filtered_sales AS (
    SELECT
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity,
        t.t_hour,
        cd_bill.cd_gender AS bill_gender,
        hd_ship.hd_vehicle_count AS ship_vehicle_count
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE
        ws.ws_web_page_sk IN (
            SELECT cp.cp_catalog_page_sk
            FROM catalog_page cp
            WHERE cp.cp_catalog_number = 5
        )
        AND cd_bill.cd_education_status = 'College'
        AND hd_ship.hd_buy_potential = 'High'
        AND t.t_hour BETWEEN 9 AND 17
        AND ws.ws_quantity > 0
)
SELECT
    t_hour,
    bill_gender,
    ship_vehicle_count,
    SUM(net_profit) AS total_net_profit,
    AVG(net_profit) AS avg_net_profit,
    COUNT(*) AS sales_cnt,
    ROW_NUMBER() OVER (ORDER BY AVG(net_profit) DESC) AS rn
FROM filtered_sales
GROUP BY
    t_hour,
    bill_gender,
    ship_vehicle_count
HAVING COUNT(*) >= 10
ORDER BY rn
LIMIT 10
