WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_catalog_page_sk AS catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 5000
      AND cs.cs_ship_hdemo_sk IN (5381, 6730)
    GROUP BY cs.cs_warehouse_sk, cs.cs_catalog_page_sk
)
SELECT
    w.w_city,
    w.w_state,
    cp.cp_department,
    cp.cp_catalog_number,
    sa.total_sales,
    sa.total_profit,
    sa.order_cnt,
    AVG(sa.total_sales) OVER (PARTITION BY w.w_city) AS avg_sales_city
FROM sales_agg sa
JOIN warehouse w ON sa.warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON sa.catalog_page_sk = cp.cp_catalog_page_sk
WHERE w.w_city = 'Salem'
  AND cp.cp_start_date_sk BETWEEN 2450905 AND 2451180
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        JOIN customer c ON cs2.cs_bill_customer_sk = c.c_customer_sk
        WHERE cs2.cs_warehouse_sk = sa.warehouse_sk
          AND cs2.cs_ext_sales_price > 8000
          AND c.c_preferred_cust_flag = 'Y'
    )
ORDER BY sa.total_sales DESC
LIMIT 100
