WITH sampled_sales AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price - cs.cs_ext_discount_amt AS net_sales,
        td.t_hour,
        cd.cd_gender,
        cd.cd_marital_status,
        cc.cc_name,
        cc.cc_state,
        cp.cp_catalog_page_number,
        cp.cp_department,
        w.w_warehouse_name,
        w.w_city,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wp.wp_link_count,
        r.r_reason_id,
        r.r_reason_desc
    FROM sampled_sales cs
    JOIN tpcds.time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr
        ON td.t_time_sk = wr.wr_returned_time_sk
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 8 AND 18                     -- predicate 1
      AND cd.cd_gender = 'M'                              -- predicate 2
      AND cc.cc_state = 'CA'                              -- predicate 3
      AND cp.cp_department = 'Electronics'               -- predicate 4
      AND w.w_city = 'New York'                           -- predicate 5
),
agg_by_call_center AS (
    SELECT
        cs_call_center_sk,
        cc_name,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_item_sk) AS distinct_items_sold,
        SUM(wr_return_amt) AS total_return_amount,
        CASE
            WHEN SUM(cs_ext_sales_price) > 500000 THEN 'HIGH'
            ELSE 'LOW'
        END AS sales_level
    FROM joined_data
    GROUP BY cs_call_center_sk, cc_name
),
filtered_agg AS (
    SELECT *
    FROM agg_by_call_center
    WHERE total_sales > 100000
      AND distinct_items_sold > 50
),
high_sales_orders AS (
    SELECT cs_order_number
    FROM joined_data
    WHERE cs_ext_sales_price > 10000
),
returned_orders AS (
    SELECT wr_order_number
    FROM tpcds.web_returns
),
orders_without_returns AS (
    SELECT cs_order_number
    FROM high_sales_orders
    EXCEPT
    SELECT wr_order_number
    FROM returned_orders
),
combined_orders AS (
    SELECT cs_order_number FROM high_sales_orders
    UNION
    SELECT cs_order_number FROM orders_without_returns
)
SELECT
    f.cs_call_center_sk,
    f.cc_name,
    f.total_sales,
    f.distinct_items_sold,
    f.total_return_amount,
    f.sales_level,
    COUNT(DISTINCT jd.cd_gender) AS distinct_genders,
    COUNT(DISTINCT jd.r_reason_id) AS distinct_reason_ids
FROM filtered_agg f
JOIN joined_data jd
    ON f.cs_call_center_sk = jd.cs_call_center_sk
WHERE jd.cs_order_number IN (SELECT cs_order_number FROM combined_orders)
GROUP BY f.cs_call_center_sk, f.cc_name, f.total_sales, f.distinct_items_sold, f.total_return_amount, f.sales_level
ORDER BY f.total_sales DESC
LIMIT 100
