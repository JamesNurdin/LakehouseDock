/*
  Net profit and sales analysis by year, income band and state for the three sales channels.
  The query aggregates store, catalog and web sales separately, then combines the results
  to show the profit margin per channel for the year 2001.
*/
WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        ca.ca_state AS state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        ca.ca_state AS state,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_state
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        ca.ca_state AS state,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound, ca.ca_state
),
combined AS (
    SELECT year, income_lower, income_upper, state, total_net_profit, total_sales, 'store'   AS channel FROM store_sales_agg
    UNION ALL
    SELECT year, income_lower, income_upper, state, total_net_profit, total_sales, 'catalog' AS channel FROM catalog_sales_agg
    UNION ALL
    SELECT year, income_lower, income_upper, state, total_net_profit, total_sales, 'web'     AS channel FROM web_sales_agg
)
SELECT
    year,
    income_lower,
    income_upper,
    state,
    channel,
    total_net_profit,
    total_sales,
    total_net_profit / total_sales AS profit_margin
FROM combined
WHERE year = 2001
ORDER BY profit_margin DESC
LIMIT 20
