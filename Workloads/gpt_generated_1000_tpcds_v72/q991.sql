WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty,
        COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_sales_price > 10
      AND ws_quantity >= 1
      AND ws_ext_discount_amt BETWEEN 0 AND 100
      AND ws_ext_tax < 50
      AND ws_coupon_amt >= 0
      AND ws_ext_ship_cost <= 30
    GROUP BY ws_warehouse_sk, ws_bill_cdemo_sk
    HAVING SUM(ws_ext_sales_price) > 500
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    w.w_gmt_offset,
    w.w_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_dep_count,
    cd.cd_dep_college_count,
    wa.total_sales,
    wa.total_qty,
    wa.order_cnt,
    RANK() OVER (PARTITION BY w.w_state ORDER BY wa.total_sales DESC) AS sales_rank_state,
    ROW_NUMBER() OVER (ORDER BY wa.total_sales DESC) AS overall_rank,
    CASE
        WHEN cd.cd_dep_count > cd.cd_dep_college_count THEN 'More dependents'
        ELSE 'College dependents'
    END AS dep_type,
    (
        SELECT MAX(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
          AND ws2.ws_bill_cdemo_sk = cd.cd_demo_sk
    ) AS max_sale_in_warehouse_demo
FROM ws_agg wa
JOIN warehouse w ON wa.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON wa.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE w.w_gmt_offset = -5.00
  AND w.w_zip IN ('33604', '29231')
  AND cd.cd_marital_status = 'M'
  AND cd.cd_dep_count >= 2
  AND wa.total_sales > 1000
  AND wa.total_qty < 500
ORDER BY overall_rank ASC
LIMIT 100
