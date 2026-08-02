WITH sales_agg AS (
    SELECT
        ss_hdemo_sk,
        ss_promo_sk,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_coupon_amt) AS avg_coupon,
        COUNT(*) AS sales_cnt
    FROM
        store_sales TABLESAMPLE BERNOULLI (5)
    WHERE
        ss_sales_price > 10
        AND ss_coupon_amt > 0
        AND ss_quantity > 0
    GROUP BY
        ss_hdemo_sk,
        ss_promo_sk
)
SELECT
    hd.hd_buy_potential,
    p.p_promo_name,
    SUM(sa.total_sales) AS sum_total_sales,
    SUM(sa.total_quantity) AS sum_total_quantity,
    AVG(sa.avg_coupon) AS avg_coupon_amount,
    SUM(sa.sales_cnt) AS total_sales_count,
    MAX(hd.hd_vehicle_count) AS max_vehicle_count,
    MIN(hd.hd_dep_count) AS min_dependency_count,
    (SELECT AVG(ss_net_paid) FROM store_sales) AS overall_avg_net_paid
FROM
    sales_agg sa
JOIN household_demographics hd
    ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
WHERE
    hd.hd_vehicle_count >= 2
    AND hd.hd_dep_count <= 5
    AND p.p_cost > 500
    AND p.p_channel_details LIKE '%High%'
GROUP BY
    hd.hd_buy_potential,
    p.p_promo_name
ORDER BY
    sum_total_sales DESC
LIMIT 100
