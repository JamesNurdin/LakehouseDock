WITH sales_data AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
),
agg_sales AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        hd_buy_potential,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_quantity) AS avg_quantity,
        SUM(cs_net_paid) / COUNT(DISTINCT cs_order_number) AS avg_paid_per_order
    FROM sales_data
    GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    total_net_paid,
    total_net_profit,
    distinct_orders,
    avg_quantity,
    avg_paid_per_order,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 10
