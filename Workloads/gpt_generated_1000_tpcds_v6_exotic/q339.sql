WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_wholesale_cost) AS avg_wholesale,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_wholesale_cost > 50
      AND cs.cs_ext_sales_price > 0
    GROUP BY cs.cs_sold_date_sk, cs.cs_sold_time_sk, cs.cs_bill_customer_sk
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    t.t_hour,
    wp.wp_type,
    s.total_sales,
    s.avg_wholesale,
    s.order_cnt,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_sold_date_sk = s.cs_sold_date_sk
    ) AS txn_count_on_date
FROM sales_agg s
JOIN date_dim d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON s.cs_sold_time_sk = t.t_time_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE d_sold.d_following_holiday = 'N'
  AND t.t_shift = 'second'
  AND wp.wp_type = 'product'
  AND NOT EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = s.cs_bill_customer_sk
          AND wp2.wp_type = 'promo'
    )
ORDER BY s.total_sales DESC
LIMIT 100
