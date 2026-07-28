WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_ship_cdemo_sk AS cd_demo_sk,
        SUM(ws_ext_sales_price) AS sum_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt,
        MIN(ws_ext_sales_price) AS min_sales,
        MAX(ws_ext_sales_price) AS max_sales
    FROM tpcds.web_sales
    WHERE ws_ext_discount_amt > 500
      AND ws_ext_discount_amt < 4000
      AND ws_coupon_amt < 3000
      AND ws_quantity >= 2
      AND ws_ext_sales_price > 1000
      AND ws_ext_sales_price < 10000
    GROUP BY ws_warehouse_sk, ws_ship_cdemo_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ws_agg.sum_sales,
    ws_agg.avg_discount,
    ws_agg.order_cnt,
    ws_agg.min_sales,
    ws_agg.max_sales,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY ws_agg.sum_sales DESC) AS warehouse_state_rank
FROM ws_agg
JOIN tpcds.warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer_demographics cd
    ON ws_agg.cd_demo_sk = cd.cd_demo_sk
WHERE w.w_zip IN ('19231', '64593', '78370')
  AND w.w_warehouse_sq_ft BETWEEN 600000 AND 950000
  AND cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'S'
  AND cd.cd_education_status = 'College'
  AND cd.cd_dep_college_count >= 2
ORDER BY w.w_state, warehouse_state_rank
