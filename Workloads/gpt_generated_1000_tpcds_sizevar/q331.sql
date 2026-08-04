SELECT
    ship_mode.sm_carrier,
    SUM(web_sales.ws_net_paid_inc_tax) AS total_paid_inc_tax
FROM
    web_sales
INNER JOIN
    ship_mode
    ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
WHERE
    ship_mode.sm_code = 'AIR'
    AND web_sales.ws_net_paid_inc_tax > 1000
GROUP BY
    ship_mode.sm_carrier
