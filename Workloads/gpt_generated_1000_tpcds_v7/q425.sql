WITH sales_agg AS (
    SELECT
        ca.ca_state AS state,
        ib.ib_lower_bound AS income_low,
        ib.ib_upper_bound AS income_high,
        SUM(ws.ws_net_profit) AS total_profit,
        CAST(NULL AS decimal(7,2)) AS total_loss
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_meal_time = 'lunch'
    GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
),
returns_agg AS (
    SELECT
        ca.ca_state AS state,
        ib.ib_lower_bound AS income_low,
        ib.ib_upper_bound AS income_high,
        CAST(NULL AS decimal(7,2)) AS total_profit,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE td.t_meal_time = 'dinner'
      AND r.r_reason_desc LIKE '%damage%'
    GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    state,
    income_low,
    income_high,
    total_profit,
    total_loss
FROM sales_agg
UNION ALL
SELECT
    state,
    income_low,
    income_high,
    total_profit,
    total_loss
FROM returns_agg
ORDER BY state, income_low
