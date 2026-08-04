WITH
    agg1 AS (
        SELECT
            w.w_warehouse_sk,
            w.w_warehouse_name,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            AVG(cs.cs_net_paid_inc_ship) AS avg_paid_inc_ship,
            COUNT(*) AS order_cnt
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_warehouse_sq_ft > 500000
          AND w.w_county LIKE '%County'
          AND cs.cs_net_paid_inc_ship > 2000
          AND cs.cs_coupon_amt < 500
        GROUP BY w.w_warehouse_sk, w.w_warehouse_name
    ),
    agg2 AS (
        SELECT
            w.w_warehouse_sk,
            w.w_warehouse_name,
            SUM(cs.cs_ext_sales_price) * 0.9 AS total_sales_adj,
            AVG(cs.cs_net_paid_inc_ship) AS avg_paid_inc_ship,
            COUNT(*) AS order_cnt
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_warehouse_sq_ft BETWEEN 200000 AND 800000
          AND w.w_county NOT LIKE '%County'
          AND cs.cs_net_paid_inc_ship BETWEEN 1000 AND 5000
          AND cs.cs_coupon_amt >= 0
        GROUP BY w.w_warehouse_sk, w.w_warehouse_name
    ),
    union_agg AS (
        SELECT w_warehouse_sk, w_warehouse_name, total_sales, avg_paid_inc_ship, order_cnt
        FROM agg1
        UNION DISTINCT
        SELECT w_warehouse_sk, w_warehouse_name, total_sales_adj, avg_paid_inc_ship, order_cnt
        FROM agg2
    ),
    key_set1 AS (SELECT w_warehouse_sk FROM agg1),
    key_set2 AS (SELECT w_warehouse_sk FROM agg2),
    intersect_keys AS (
        SELECT w_warehouse_sk FROM key_set1
        INTERSECT
        SELECT w_warehouse_sk FROM key_set2
    ),
    final_agg AS (
        SELECT
            u.w_warehouse_sk,
            u.w_warehouse_name,
            SUM(u.total_sales) AS sum_total_sales,
            AVG(u.avg_paid_inc_ship) AS avg_of_avg_paid,
            SUM(u.order_cnt) AS total_orders
        FROM union_agg u
        JOIN intersect_keys i ON u.w_warehouse_sk = i.w_warehouse_sk
        GROUP BY u.w_warehouse_sk, u.w_warehouse_name
        HAVING SUM(u.total_sales) > 10000
    )
SELECT
    w_warehouse_sk,
    w_warehouse_name,
    sum_total_sales,
    avg_of_avg_paid,
    total_orders
FROM final_agg
WHERE sum_total_sales > 15000
ORDER BY sum_total_sales DESC
OFFSET 10 ROWS
LIMIT 100
