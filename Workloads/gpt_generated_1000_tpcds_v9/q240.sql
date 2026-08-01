WITH pref_cust AS (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
agg_sales AS (
    SELECT
        c.c_birth_country AS birth_country,
        ib.ib_lower_bound AS income_lower,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date >= DATE '2001-01-01'
      AND sm.sm_carrier = 'UPS'
      AND ib.ib_lower_bound >= 50000
      AND hd.hd_buy_potential = '501-1000'
      AND c.c_customer_sk IN (SELECT c_customer_sk FROM pref_cust)
      AND wp.wp_customer_sk = c.c_customer_sk
    GROUP BY ROLLUP (c.c_birth_country, ib.ib_lower_bound)
)
SELECT
    birth_country,
    income_lower,
    total_net_profit,
    avg_net_paid,
    order_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    CASE
        WHEN total_net_profit > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_vs_overall_avg
FROM agg_sales
ORDER BY profit_rank
LIMIT 100
