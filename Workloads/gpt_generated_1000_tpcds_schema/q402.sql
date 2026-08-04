WITH agg_sales AS (
    SELECT
        cs_bill_cdemo_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_coupon_amt) AS avg_coupon,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_coupon_amt > 500
      AND cs_net_paid_inc_ship < 8000
      AND cs_ship_addr_sk IN (4806430, 2000933)
    GROUP BY cs_bill_cdemo_sk, cs_sold_time_sk
),
joined AS (
    SELECT
        a.cs_bill_cdemo_sk,
        a.cs_sold_time_sk,
        a.total_sales,
        a.avg_coupon,
        a.sales_cnt,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        td.t_sub_shift,
        td.t_second,
        td.t_meal_time
    FROM agg_sales a
    JOIN customer_demographics cd
        ON a.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td
        ON a.cs_sold_time_sk = td.t_time_sk
    WHERE cd.cd_marital_status = 'M'
      AND cd.cd_dep_employed_count >= 4
      AND cd.cd_dep_college_count <= 2
      AND td.t_sub_shift = 'afternoon'
      AND td.t_second BETWEEN 0 AND 15
      AND td.t_meal_time = 'dinner'
)
SELECT
    j.cs_bill_cdemo_sk,
    j.cd_gender,
    j.cd_marital_status,
    j.t_sub_shift,
    u.metric_idx,
    SUM(u.metric) AS metric_sum,
    COUNT(*) AS metric_cnt,
    (SELECT MAX(cs_ext_sales_price) FROM catalog_sales WHERE cs_coupon_amt > 1000) AS global_max_ext_sales_price
FROM joined j
CROSS JOIN UNNEST(ARRAY[j.total_sales, j.avg_coupon]) WITH ORDINALITY AS u(metric, metric_idx)
GROUP BY
    j.cs_bill_cdemo_sk,
    j.cd_gender,
    j.cd_marital_status,
    j.t_sub_shift,
    u.metric_idx
ORDER BY metric_sum DESC
LIMIT 100
