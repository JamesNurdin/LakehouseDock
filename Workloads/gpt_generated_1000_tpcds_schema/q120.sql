WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_time_sk,
        cs_bill_cdemo_sk,
        cs_warehouse_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_ext_sales_price > 200
      AND cs_quantity >= 2
      AND cs_ship_hdemo_sk IN (1756, 1977, 2581)
    GROUP BY cs_item_sk, cs_sold_time_sk, cs_bill_cdemo_sk, cs_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    t.t_hour,
    t.t_minute,
    cd.cd_education_status,
    w.w_warehouse_name,
    w.w_country,
    s.total_sales,
    s.avg_discount,
    s.sales_cnt
FROM sales_agg s
FULL OUTER JOIN warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
JOIN time_dim t
    ON s.cs_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
    ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE i.i_category_id = 7
  AND t.t_hour BETWEEN 9 AND 17
  AND cd.cd_gender = 'F'
ORDER BY s.total_sales DESC
LIMIT 100
