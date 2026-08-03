WITH filtered_sales AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_ext_wholesale_cost > 1000
      AND ws.ws_ext_sales_price IS NOT NULL
),
joined AS (
    SELECT
        ca.ca_state,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        c.c_birth_year,
        f.ws_net_profit,
        f.ws_ext_wholesale_cost
    FROM filtered_sales f
    JOIN customer c
        ON f.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON f.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON f.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 4
      AND ib.ib_upper_bound <= 120000
      AND ca.ca_state = 'CA'
      AND c.c_birth_year BETWEEN 1970 AND 1990
)
SELECT
    ca_state,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ws_net_profit) AS total_profit,
    SUM(ws_ext_wholesale_cost) AS total_wholesale_cost,
    CASE
        WHEN SUM(ws_net_profit) > 100000 THEN 'High'
        WHEN SUM(ws_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ws_net_profit) DESC) AS profit_rank_state
FROM joined
GROUP BY ROLLUP (ca_state, hd_buy_potential, ib_lower_bound, ib_upper_bound)
ORDER BY ca_state NULLS LAST,
         hd_buy_potential NULLS LAST,
         total_profit DESC
LIMIT 100
