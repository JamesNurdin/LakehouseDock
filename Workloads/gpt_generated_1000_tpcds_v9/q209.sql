WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
hd_income AS (
    SELECT 
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics AS hd
    JOIN income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 20000
),
joined AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_order_number,
        cs.cs_list_price,
        cs.cs_coupon_amt,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_ext_tax,
        cs.cs_ext_ship_cost,
        t.t_time,
        t.t_second,
        hd_income.hd_demo_sk,
        hd_income.hd_buy_potential,
        hd_income.hd_dep_count,
        hd_income.ib_lower_bound,
        hd_income.ib_upper_bound
    FROM cs_sample AS cs
    FULL OUTER JOIN time_dim AS t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN hd_income
        ON cs.cs_bill_hdemo_sk = hd_income.hd_demo_sk
           OR cs.cs_ship_hdemo_sk = hd_income.hd_demo_sk
    WHERE cs.cs_list_price > 50
      AND cs.cs_coupon_amt > 0
      AND hd_income.hd_dep_count >= 3
      AND t.t_second BETWEEN 0 AND 10
),
grouped AS (
    SELECT
        hd_buy_potential,
        ib_lower_bound,
        ib_upper_bound,
        t_time,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cs_net_profit) AS avg_net_profit,
        MIN(cs_coupon_amt) AS min_coupon_amt,
        MAX(cs_coupon_amt) AS max_coupon_amt
    FROM joined
    GROUP BY hd_buy_potential, ib_lower_bound, ib_upper_bound, t_time
    HAVING SUM(cs_net_paid) > 1000
)
SELECT
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    t_time,
    order_cnt,
    total_net_paid,
    avg_net_profit,
    min_coupon_amt,
    max_coupon_amt,
    SUM(total_net_paid) OVER (
        PARTITION BY hd_buy_potential
        ORDER BY t_time
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid,
    RANK() OVER (
        PARTITION BY hd_buy_potential
        ORDER BY total_net_paid DESC
    ) AS net_paid_rank
FROM grouped
ORDER BY total_net_paid DESC
LIMIT 100
