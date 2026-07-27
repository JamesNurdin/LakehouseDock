/* goal: Analyze net profit performance by customer, quarter and income band, showing subtotals, ranking customers within each quarter, and categorizing profit levels. */
WITH base AS (
    SELECT
        c.c_customer_id,
        d_sold.d_quarter_name,
        ib.ib_income_band_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sales_price
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year = 2001
      AND hd.hd_buy_potential = '1001-5000'
      AND ws.ws_quantity > 2
      AND ib.ib_upper_bound <= (
          SELECT max(ib2.ib_upper_bound)
          FROM income_band ib2
      )
),
agg AS (
    SELECT
        c_customer_id,
        d_quarter_name,
        ib_income_band_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        CASE
            WHEN SUM(ws_net_profit) > 10000 THEN 'High'
            ELSE 'Low'
        END AS profit_category,
        GROUPING(c_customer_id) AS g_customer,
        GROUPING(d_quarter_name) AS g_quarter,
        GROUPING(ib_income_band_sk) AS g_income_band
    FROM base
    GROUP BY ROLLUP (c_customer_id, d_quarter_name, ib_income_band_sk)
    HAVING SUM(ws_net_profit) > 5000
)
SELECT
    c_customer_id,
    d_quarter_name,
    ib_income_band_sk,
    total_quantity,
    total_profit,
    avg_sales_price,
    profit_category,
    g_customer,
    g_quarter,
    g_income_band,
    RANK() OVER (PARTITION BY d_quarter_name ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY d_quarter_name, profit_rank
LIMIT 100
