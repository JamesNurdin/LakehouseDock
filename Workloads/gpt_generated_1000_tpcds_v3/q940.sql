WITH base_agg AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        cd_sales.cd_gender AS gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(ss.ss_ext_sales_price) - SUM(wr.wr_return_amt) AS net_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
        (SELECT AVG(ss2.ss_ext_discount_amt) FROM store_sales ss2) AS overall_avg_discount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd_sales
        ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd_refunded
        ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
        AND cp.cp_department = 'DEPARTMENT'
        AND ss.ss_quantity > 1
        AND wp.wp_autogen_flag = 'N'
    GROUP BY d.d_year, cp.cp_department, cd_sales.cd_gender
)
SELECT
    department,
    SUM(total_sales) AS dept_total_sales,
    SUM(total_returns) AS dept_total_returns,
    SUM(net_sales) AS dept_net_sales,
    AVG(avg_sales_price) AS dept_avg_sales_price,
    SUM(distinct_pages) AS dept_total_pages,
    MAX(overall_avg_discount) AS overall_avg_discount
FROM base_agg
GROUP BY department
HAVING SUM(total_sales) > 10000
ORDER BY dept_net_sales DESC
LIMIT 100
