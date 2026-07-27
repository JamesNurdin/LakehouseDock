WITH sales_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        wp.wp_type,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        MIN(cs.cs_ext_sales_price) AS min_sale,
        MAX(cs.cs_ext_sales_price) AS max_sale
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity > 2
      AND cs.cs_net_profit > 0
      AND w.w_zip = '36098'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          JOIN web_page wp2
              ON wr.wr_web_page_sk = wp2.wp_web_page_sk
          WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
            AND wr.wr_return_amt > 100
            AND wp2.wp_max_ad_count = 2
      )
    GROUP BY w.w_warehouse_id, w.w_city, wp.wp_type
)
SELECT DISTINCT
    s.w_warehouse_id,
    s.w_city,
    s.wp_type,
    s.distinct_customers,
    s.total_sales,
    s.avg_profit,
    s.min_sale,
    s.max_sale
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
