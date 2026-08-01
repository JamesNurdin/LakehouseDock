WITH ss_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_sales_price > 100.00
      AND ss_quantity > 1
    GROUP BY ss_sold_date_sk, ss_sold_time_sk
)
SELECT *
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        cp.cp_department,
        wp.wp_type,
        r.r_reason_desc,
        ss_agg.total_sales,
        ss_agg.total_discount,
        ss_agg.sales_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(DISTINCT wr.wr_order_number) AS return_orders
    FROM ss_agg
    RIGHT OUTER JOIN date_dim d
        ON ss_agg.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss_agg.ss_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND d.d_current_year = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Electronics'
      AND wp.wp_type = 'Content'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_returned_date_sk = d.d_date_sk
            AND wr2.wr_reason_sk = r.r_reason_sk
            AND wr2.wr_return_amt > 50
      )
    GROUP BY d.d_year, d.d_month_seq, t.t_hour,
             cp.cp_department, wp.wp_type, r.r_reason_desc,
             ss_agg.total_sales, ss_agg.total_discount, ss_agg.sales_cnt
    HAVING SUM(wr.wr_return_amt_inc_tax) > 500

    INTERSECT

    SELECT
        d2.d_year,
        d2.d_month_seq,
        t2.t_hour,
        cp2.cp_department,
        wp2.wp_type,
        r2.r_reason_desc,
        ss_agg2.total_sales,
        ss_agg2.total_discount,
        ss_agg2.sales_cnt,
        SUM(wr2.wr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(DISTINCT wr2.wr_order_number) AS return_orders
    FROM ss_agg AS ss_agg2
    RIGHT OUTER JOIN date_dim d2
        ON ss_agg2.ss_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2
        ON ss_agg2.ss_sold_time_sk = t2.t_time_sk
    JOIN catalog_page cp2
        ON cp2.cp_start_date_sk = d2.d_date_sk
    JOIN web_page wp2
        ON wp2.wp_creation_date_sk = d2.d_date_sk
    JOIN web_returns wr2
        ON wr2.wr_returned_date_sk = d2.d_date_sk
        AND wr2.wr_returned_time_sk = t2.t_time_sk
    JOIN reason r2
        ON wr2.wr_reason_sk = r2.r_reason_sk
    WHERE d2.d_year = 2002
      AND d2.d_current_year = 'Y'
    GROUP BY d2.d_year, d2.d_month_seq, t2.t_hour,
             cp2.cp_department, wp2.wp_type, r2.r_reason_desc,
             ss_agg2.total_sales, ss_agg2.total_discount, ss_agg2.sales_cnt
) AS intersected_result
LIMIT 100
