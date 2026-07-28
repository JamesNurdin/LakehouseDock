WITH sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 1
      AND ss_net_paid IS NOT NULL
    GROUP BY ss_customer_sk, ss_item_sk, ss_sold_date_sk
)
SELECT
    cc.cc_name,
    cd.cd_gender,
    CASE WHEN sa.total_net_paid > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
    SUM(sa.total_net_paid) AS sum_net_paid,
    SUM(sa.total_quantity) AS sum_quantity,
    AVG(sa.avg_discount) AS avg_discount_overall,
    COUNT(DISTINCT sa.ss_customer_sk) AS distinct_customers
FROM sales_agg sa
JOIN customer cu ON sa.ss_customer_sk = cu.c_customer_sk
JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
WHERE cc.cc_company = 2
  AND cc.cc_sq_ft > 1000000
  AND cu.c_birth_year BETWEEN 1970 AND 1985
  AND i.i_wholesale_cost < 5.00
  AND i.i_manager_id IN (26, 34)
  AND d_sales.d_year = 2002
GROUP BY
    cc.cc_name,
    cd.cd_gender,
    CASE WHEN sa.total_net_paid > 10000 THEN 'HIGH' ELSE 'NORMAL' END
HAVING SUM(sa.total_net_paid) > 20000
ORDER BY sum_net_paid DESC
LIMIT 100
