WITH demo_sales AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_list_price) AS avg_list_price
    FROM
        household_demographics AS hd
        JOIN web_sales AS ws
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_vehicle_count >= 1
        AND hd.hd_vehicle_count <= 4
        AND hd.hd_buy_potential IN ('>10000', '5001-10000')
        AND ws.ws_ext_list_price > 500
        AND ws.ws_ext_list_price < 8000
        AND ws.ws_quantity >= 1
        AND ws.ws_quantity <= 10
        AND ws.ws_net_paid > 1000
        AND ws.ws_ship_mode_sk IN (1, 2, 3)
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count
)
SELECT
    hd_buy_potential,
    hd_vehicle_count,
    COUNT(*) AS demo_count,
    SUM(total_net_paid) AS sum_net_paid,
    AVG(total_net_paid) AS avg_net_paid,
    SUM(total_quantity) AS sum_quantity,
    AVG(avg_list_price) AS avg_list_price_over_demos
FROM demo_sales
GROUP BY
    hd_buy_potential,
    hd_vehicle_count
HAVING
    SUM(total_net_paid) > 5000
    AND AVG(total_quantity) > 2
ORDER BY
    avg_net_paid DESC
LIMIT 100
