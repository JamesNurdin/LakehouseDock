WITH sales_demo AS (
    SELECT
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_net_profit,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_customer_sk
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    -- Use the rule linking a customer to its current household demographics
    JOIN household_demographics hd_cust
        ON c.c_current_hdemo_sk = hd_cust.hd_demo_sk
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_ext_discount_amt) AS total_discount,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_net_profit) / NULLIF(SUM(ss_ext_sales_price), 0) AS profit_ratio,
    SUM(ss_ext_discount_amt) / NULLIF(SUM(ss_ext_sales_price), 0) AS discount_ratio
FROM sales_demo
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
ORDER BY total_net_profit DESC
LIMIT 10
