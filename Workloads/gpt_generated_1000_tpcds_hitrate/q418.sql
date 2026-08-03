WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_tax) AS total_tax
    FROM tpcds.store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_ext_sales_price > 100
      AND ss_ext_tax > 0
      AND ss_coupon_amt < 500
    GROUP BY ss_store_sk, ss_customer_sk
),
joined AS (
    SELECT
        sa.ss_store_sk,
        s.s_store_name,
        s.s_state,
        sa.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        t.t_hour,
        t.t_meal_time,
        sa.total_sales,
        sa.total_tax
    FROM sales_agg sa
    FULL OUTER JOIN tpcds.store s
        ON sa.ss_store_sk = s.s_store_sk
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
       AND ss.ss_customer_sk = sa.ss_customer_sk
    LEFT JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag = 'N')
      AND ca.ca_country = 'United States'
      AND s.s_closed_date_sk IS NULL
      AND EXISTS (
          SELECT 1
          FROM tpcds.customer_address ca2
          WHERE ca2.ca_address_sk = c.c_current_addr_sk
            AND ca2.ca_city = 'Seattle'
      )
)
SELECT
    agg.s_state,
    agg.s_store_name,
    CASE
        WHEN agg.sum_total_sales >= 10000 THEN 'Platinum'
        WHEN agg.sum_total_sales >= 5000 THEN 'Gold'
        ELSE 'Silver'
    END AS sales_tier,
    agg.sum_total_sales,
    agg.sum_total_tax,
    RANK() OVER (PARTITION BY agg.s_state ORDER BY agg.sum_total_sales DESC) AS state_sales_rank
FROM (
    SELECT
        j.s_state,
        j.s_store_name,
        SUM(j.total_sales) AS sum_total_sales,
        SUM(j.total_tax) AS sum_total_tax
    FROM joined j
    GROUP BY ROLLUP (j.s_state, j.s_store_name)
) agg
ORDER BY agg.s_state NULLS LAST, agg.sum_total_sales DESC
LIMIT 100
