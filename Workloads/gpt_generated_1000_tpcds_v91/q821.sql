WITH aggregated AS (
    SELECT
        ws_site.web_name,
        ws_site.web_zip,
        td.t_sub_shift,
        cd.cd_gender,
        COUNT(*) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_ship_cost) AS avg_ship_cost
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws_site.web_site_sk IN (
        SELECT DISTINCT ws2.ws_web_site_sk
        FROM web_sales ws2
        WHERE ws2.ws_ext_ship_cost > 2000
    )
      AND cd.cd_gender = 'M'
      AND ca.ca_country = 'United States'
      AND td.t_sub_shift = 'morning'
      AND ws.ws_ext_ship_cost > 1000
    GROUP BY ws_site.web_name, ws_site.web_zip, td.t_sub_shift, cd.cd_gender
)
SELECT
    web_name,
    web_zip,
    t_sub_shift,
    cd_gender,
    order_count,
    total_profit,
    avg_ship_cost,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY web_zip ORDER BY total_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_zip,
    CASE WHEN total_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    (SELECT MAX(ws_ext_ship_cost) FROM web_sales) AS max_ship_cost_overall
FROM aggregated
ORDER BY profit_rank ASC, web_name ASC
LIMIT 100
