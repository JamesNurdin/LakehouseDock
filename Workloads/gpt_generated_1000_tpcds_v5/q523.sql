WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE
            WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High'
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (12, 16, 18, 10)
      AND hd.hd_buy_potential IN ('5001-10000', '>10000')
      AND ws.ws_sold_time_sk BETWEEN 40000 AND 80000
      AND c.c_birth_year BETWEEN 1950 AND 1990
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
)
SELECT
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.c_birth_year,
    s.hd_income_band_sk,
    s.hd_buy_potential,
    s.total_profit,
    s.total_sales,
    s.profit_category,
    RANK() OVER (PARTITION BY s.hd_income_band_sk ORDER BY s.total_profit DESC) AS profit_rank_in_income_band
FROM sales_agg s
ORDER BY s.hd_income_band_sk, profit_rank_in_income_band
LIMIT 100
