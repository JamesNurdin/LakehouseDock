WITH sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_qty,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS order_count
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
      AND ss_quantity >= 2
      AND ss_net_paid_inc_tax > 2000
      AND ss_list_price < 200
    GROUP BY ss_sold_date_sk, ss_customer_sk
),
joined AS (
    SELECT
        agg.ss_sold_date_sk,
        agg.ss_customer_sk,
        agg.total_sales,
        agg.total_qty,
        agg.total_profit,
        d.d_year,
        d.d_month_seq,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        d.d_current_year
    FROM sales_agg agg
    INNER JOIN date_dim d
        ON agg.ss_sold_date_sk = d.d_date_sk
    INNER JOIN customer c
        ON agg.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year > 1970
      AND d.d_current_year = 'Y'
),
aggregated AS (
    SELECT
        d_year,
        c_preferred_cust_flag,
        SUM(total_sales) AS sum_sales,
        SUM(total_qty) AS sum_qty,
        SUM(total_profit) AS sum_profit,
        AVG(total_profit / NULLIF(total_sales, 0)) AS avg_profit_margin
    FROM joined
    GROUP BY ROLLUP(d_year, c_preferred_cust_flag)
    HAVING SUM(total_sales) > 5000
)
SELECT
    d_year,
    c_preferred_cust_flag,
    sum_sales,
    sum_qty,
    sum_profit,
    avg_profit_margin,
    ROW_NUMBER() OVER (PARTITION BY c_preferred_cust_flag ORDER BY sum_sales DESC) AS rn
FROM aggregated
ORDER BY d_year ASC NULLS LAST,
         c_preferred_cust_flag ASC NULLS LAST,
         sum_sales DESC
LIMIT 100
