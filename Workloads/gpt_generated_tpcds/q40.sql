WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        t.t_hour,
        c.c_preferred_cust_flag
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_date >= DATE '2020-01-01'
      AND d.d_date <= DATE '2020-12-31'
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    AVG(ss_quantity) AS avg_quantity_per_sale
FROM sales_data
GROUP BY d_year, d_month_seq, i_category, i_brand
ORDER BY d_year, d_month_seq, total_net_paid DESC
