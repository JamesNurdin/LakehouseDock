WITH filtered_sales AS (
    SELECT
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_type,
        d_sold.d_year,
        d_sold.d_month_seq
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE d_sold.d_date >= DATE '2021-01-01'
      AND d_sold.d_date < DATE '2022-01-01'
      AND d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date
),
dept_month_agg AS (
    SELECT
        cp_department,
        cp_type,
        d_year,
        d_month_seq,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        SUM(cs_net_profit) AS total_net_profit
    FROM filtered_sales
    GROUP BY
        cp_department,
        cp_type,
        d_year,
        d_month_seq
)
SELECT
    cp_department,
    cp_type,
    d_year,
    d_month_seq,
    total_quantity,
    total_sales,
    total_discount,
    total_net_profit,
    dept_rank
FROM (
    SELECT
        cp_department,
        cp_type,
        d_year,
        d_month_seq,
        total_quantity,
        total_sales,
        total_discount,
        total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS dept_rank
    FROM dept_month_agg
) t
WHERE dept_rank <= 3
ORDER BY d_year, d_month_seq, dept_rank
