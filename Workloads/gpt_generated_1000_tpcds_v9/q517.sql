WITH sales_agg AS (
    SELECT
        d.d_year,
        w.web_site_sk,
        w.web_name,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(*) AS order_cnt,
        (
            SELECT MAX(ws2.ws_ext_ship_cost)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = w.web_site_sk
        ) AS max_ship_cost_per_site,
        MAX(ship_info.first_ship_date) AS first_ship_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    CROSS JOIN LATERAL (
        SELECT MIN(d2.d_date) AS first_ship_date
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_ship_date_sk = d2.d_date_sk
        WHERE ws2.ws_web_site_sk = w.web_site_sk
    ) AS ship_info
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND t.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count >= 1
      AND w.web_state = 'CA'
    GROUP BY ROLLUP (d.d_year, w.web_site_sk, w.web_name)
)
SELECT
    d_year,
    web_name,
    total_ext_sales,
    avg_net_profit,
    order_cnt,
    max_ship_cost_per_site,
    first_ship_date,
    ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY total_ext_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY d_year ASC NULLS LAST, total_ext_sales DESC
LIMIT 100
