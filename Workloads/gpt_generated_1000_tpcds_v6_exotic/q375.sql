WITH sales_a AS (
    SELECT
        w.w_city AS city,
        d.d_month_seq AS month_seq,
        regexp_extract(w.w_street_name, '(\\w+) Park$', 1) AS street_prefix,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE '%York%'
      AND regexp_like(w.w_street_name, 'Park$')
    GROUP BY ROLLUP (w.w_city, d.d_month_seq, w.w_street_name)
),
sales_b AS (
    SELECT
        w.w_city AS city,
        d.d_month_seq AS month_seq,
        regexp_extract(w.w_street_name, '(\\w+) Drive$', 1) AS street_prefix,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE '%County%'
      AND regexp_like(w.w_street_name, 'Drive$')
    GROUP BY ROLLUP (w.w_city, d.d_month_seq, w.w_street_name)
),
combined AS (
    SELECT city, month_seq, street_prefix, sales_amount, sales_cnt FROM sales_a
    UNION ALL
    SELECT city, month_seq, street_prefix, sales_amount, sales_cnt FROM sales_b
)
SELECT
    city,
    month_seq,
    street_prefix,
    SUM(sales_amount) AS total_sales,
    SUM(sales_cnt)    AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY SUM(sales_amount) DESC) AS sales_rank,
    SUM(SUM(sales_amount)) OVER (PARTITION BY city) AS city_total_sales
FROM combined
GROUP BY ROLLUP (city, month_seq, street_prefix)
ORDER BY city, month_seq, street_prefix
LIMIT 100
