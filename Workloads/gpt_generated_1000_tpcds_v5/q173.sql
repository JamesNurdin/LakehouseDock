WITH monthly_total AS (
    SELECT
        d2.d_year,
        d2.d_month_seq,
        SUM(ss2.ss_net_profit) + SUM(ws2.ws_net_profit) AS month_profit
    FROM date_dim d2
    JOIN store_sales ss2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    JOIN web_sales ws2 ON ws2.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
    GROUP BY d2.d_year, d2.d_month_seq
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) + SUM(ws.ws_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) DESC) AS profit_rank,
    CASE
        WHEN (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) >
             (SELECT AVG(month_profit) FROM monthly_total mt WHERE mt.d_year = d.d_year)
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM date_dim d
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON i.i_item_sk = ss.ss_item_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
WHERE d.d_year = 2001
  AND i.i_current_price > 50
  AND cd.cd_gender = 'M'
  AND sm.sm_type = 'AIR'
  AND cp.cp_department = 'Electronics'
GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
ORDER BY total_net_profit DESC
