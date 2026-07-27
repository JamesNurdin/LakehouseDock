WITH base AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(sales.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(sales.ss_net_profit) + SUM(ws.ws_net_profit) AS total_profit
    FROM (
        SELECT ss.ss_store_sk,
               ss.ss_net_profit,
               ss.ss_sold_date_sk,
               ss.ss_hdemo_sk
        FROM store_sales ss
    ) sales
    JOIN date_dim d1 ON sales.ss_sold_date_sk = d1.d_date_sk
    JOIN store s ON sales.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sales.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
                     AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d2 ON ws.ws_ship_date_sk = d2.d_date_sk
    WHERE d1.d_year = 2001
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND sm.sm_type = 'AIR'
      AND wp.wp_type = 'HOME'
      AND s.s_zip LIKE '39%'
    GROUP BY s.s_store_id, s.s_city, s.s_state
)
SELECT
    b.s_store_id,
    b.s_city,
    b.s_state,
    b.store_sales_profit,
    b.web_sales_profit,
    b.total_profit,
    RANK() OVER (ORDER BY b.total_profit DESC) AS profit_rank,
    CASE
        WHEN b.total_profit > 1000000 THEN 'HIGH'
        WHEN b.total_profit > 500000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (
        SELECT AVG(ws3.ws_net_profit)
        FROM web_sales ws3
        JOIN date_dim d3 ON ws3.ws_sold_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
    ) AS avg_web_profit_2001
FROM base b
ORDER BY b.total_profit DESC
LIMIT 100
