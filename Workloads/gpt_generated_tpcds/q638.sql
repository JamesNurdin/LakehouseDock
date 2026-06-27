-- Top 10 income bands (by net profit) for preferred customers, broken out by buying potential
WITH preferred_sales AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit)               AS total_net_profit,
        SUM(cs.cs_ext_sales_price)          AS total_sales,
        AVG(cs.cs_quantity)                 AS avg_quantity,
        AVG(cs.cs_ext_discount_amt)         AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number)  AS distinct_orders,
        COUNT(DISTINCT c.c_customer_sk)     AS distinct_customers
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    total_net_profit,
    total_sales,
    avg_quantity,
    avg_discount,
    distinct_orders,
    distinct_customers
FROM preferred_sales
ORDER BY total_net_profit DESC
LIMIT 10
