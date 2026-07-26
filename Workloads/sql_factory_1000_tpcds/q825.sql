WITH cust_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt,
        AVG(ss.ss_quantity) AS avg_qty,
        MIN(t.t_hour) AS first_purchase_hour,
        MAX(t.t_hour) AS last_purchase_hour,
        COUNT(DISTINCT t.t_hour) AS distinct_purchase_hours
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_birth_year,
    cs.hd_income_band_sk,
    cs.hd_buy_potential,
    cs.total_sales,
    cs.total_profit,
    cs.txn_cnt,
    cs.avg_qty,
    cs.first_purchase_hour,
    cs.last_purchase_hour,
    cs.distinct_purchase_hours,
    CASE
        WHEN cs.total_sales >= 200000 THEN 'Platinum'
        WHEN cs.total_sales >= 100000 THEN 'Gold'
        WHEN cs.total_sales >= 50000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
    DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_dense_rank
FROM cust_sales cs
ORDER BY sales_rank
LIMIT 20
