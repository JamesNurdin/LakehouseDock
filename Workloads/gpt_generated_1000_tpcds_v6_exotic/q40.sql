WITH sales_agg AS (
    SELECT
        cs_ship_mode_sk,
        cs_ship_date_sk,
        cs_ship_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_qty,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM catalog_sales
    WHERE cs_sales_price > 50
      AND cs_ext_ship_cost < 1000
      AND cs_quantity BETWEEN 1 AND 10
    GROUP BY cs_ship_mode_sk, cs_ship_date_sk, cs_ship_customer_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    d.d_date,
    c.c_email_address,
    sales_agg.total_sales,
    sales_agg.total_qty,
    sales_agg.order_cnt
FROM sales_agg
JOIN ship_mode sm
  ON sales_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d
  ON sales_agg.cs_ship_date_sk = d.d_date_sk
JOIN customer c
  ON sales_agg.cs_ship_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND sm.sm_type = 'AIR'
  AND c.c_email_address LIKE '%@%.com'
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND sm.sm_carrier = 'UPS'
  AND sales_agg.total_sales > (
        SELECT AVG(t.total_sales)
        FROM (
            SELECT SUM(cs_ext_sales_price) AS total_sales
            FROM catalog_sales
            GROUP BY cs_ship_mode_sk
        ) t
    )
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE cs2.cs_ship_customer_sk = c.c_customer_sk
          AND d2.d_year = 2001
          AND cs2.cs_sales_price > 80
    )
ORDER BY sales_agg.total_sales DESC
LIMIT 100
