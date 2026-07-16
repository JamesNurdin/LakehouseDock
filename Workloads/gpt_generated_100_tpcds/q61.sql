WITH sales_by_income AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_bill_customer_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
agg AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        COUNT(DISTINCT ws_bill_customer_sk) AS distinct_customers,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_sales_price) AS avg_sales_per_transaction,
        SUM(ws_quantity) AS total_quantity_sold
    FROM sales_by_income
    GROUP BY ib_lower_bound, ib_upper_bound
),
ranked AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        distinct_customers,
        total_sales,
        total_discount,
        total_profit,
        avg_sales_per_transaction,
        total_quantity_sold,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM agg
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    distinct_customers,
    total_sales,
    total_discount,
    total_profit,
    avg_sales_per_transaction,
    total_quantity_sold,
    sales_rank
FROM ranked
ORDER BY sales_rank
