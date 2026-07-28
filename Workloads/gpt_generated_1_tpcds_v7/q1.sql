WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sale_year,
        sm.sm_carrier AS carrier,
        ib.ib_income_band_sk AS income_band_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_sold.d_date = DATE '2001-01-01'                -- filter on a DATE column
      AND d_sold.d_dow = 2                                 -- filter on day of week (sample value)
      AND ib.ib_lower_bound >= 80000 AND ib.ib_upper_bound <= 150000  -- income band filter
      AND ws.ws_quantity > 10                              -- sales quantity filter
    GROUP BY d_sold.d_year, sm.sm_carrier, ib.ib_income_band_sk
)
SELECT
    sale_year,
    carrier,
    income_band_sk,
    total_profit,
    avg_quantity,
    distinct_orders
FROM sales_agg
ORDER BY total_profit DESC, sale_year ASC
LIMIT 100
