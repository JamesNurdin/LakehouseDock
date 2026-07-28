WITH agg AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        MIN(ss.ss_ext_sales_price) AS min_ext_sales,
        MAX(ss.ss_ext_sales_price) AS max_ext_sales
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_dep_count >= 2
        AND hd.hd_vehicle_count = 1
        AND ss.ss_coupon_amt > 50.00
    GROUP BY
        hd.hd_income_band_sk,
        hd.hd_buy_potential
)
SELECT
    hd_income_band_sk,
    hd_buy_potential,
    total_net_paid,
    avg_discount,
    sales_cnt,
    min_ext_sales,
    max_ext_sales,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank,
    SUM(total_net_paid) OVER (
        ORDER BY total_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
