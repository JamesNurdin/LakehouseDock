WITH
-- Base fact table with star joins (using aliases for repeated tables)
sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        store.s_store_name,
        hd1.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        time_dim.t_hour,
        time_dim.t_am_pm,
        ARRAY[CAST(ss.ss_quantity AS decimal(7,2)), ss.ss_ext_sales_price] AS measures_array
    FROM store_sales ss
    JOIN item i                                 ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c1                            ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN household_demographics hd1             ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN income_band ib                         ON hd1.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store                                   ON ss.ss_store_sk = store.s_store_sk
    JOIN time_dim                               ON ss.ss_sold_time_sk = time_dim.t_time_sk
),
-- Catalog returns side (second use of customer & household_demographics under different aliases)
returns_catalog AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        cr.cr_warehouse_sk,
        reason.r_reason_desc,
        warehouse.w_warehouse_name,
        time_dim.t_hour AS return_hour,
        c2.c_customer_id AS refunded_cust_id,
        hd2.hd_income_band_sk AS refunded_income_band_sk
    FROM catalog_returns cr
    JOIN item i                                 ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c2                            ON cr.cr_refunded_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2             ON cr.cr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN reason                                 ON cr.cr_reason_sk = reason.r_reason_sk
    JOIN warehouse                              ON cr.cr_warehouse_sk = warehouse.w_warehouse_sk
    JOIN time_dim                               ON cr.cr_returned_time_sk = time_dim.t_time_sk
),
-- Web returns side (also uses reason and joins to web_page)
returns_web AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_return_amt,
        wr.wr_reason_sk,
        reason.r_reason_desc AS web_reason,
        web_page.wp_url,
        time_dim.t_hour AS web_return_hour,
        c3.c_customer_id AS web_refunded_cust_id
    FROM web_returns wr
    JOIN item i                                 ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c3                            ON wr.wr_refunded_customer_sk = c3.c_customer_sk
    JOIN household_demographics hd3             ON wr.wr_refunded_hdemo_sk = hd3.hd_demo_sk
    JOIN reason                                 ON wr.wr_reason_sk = reason.r_reason_sk
    JOIN web_page                               ON wr.wr_web_page_sk = web_page.wp_web_page_sk
    JOIN time_dim                               ON wr.wr_returned_time_sk = time_dim.t_time_sk
),
-- Main analytical query
main_query AS (
    SELECT
        sb.s_store_name,
        sb.i_category,
        SUM(CAST(sb.measures_array[2] AS decimal(7,2)))                         AS total_sales_amount,
        COALESCE(SUM(rc.cr_return_amount), 0)                                   AS total_return_amount,
        COUNT(DISTINCT sb.ss_customer_sk)                                       AS distinct_customers,
        COUNT(DISTINCT sb.i_brand)                                              AS distinct_brands,
        (SELECT AVG(i_current_price) FROM item)                                AS avg_item_price,
        (SELECT SUM(wr.wr_return_amt)                                          
         FROM web_returns wr                                                   
         WHERE wr.wr_refunded_customer_sk = sb.ss_customer_sk)                AS customer_web_return_total,
        SUM(measure_value)                                                      AS total_measures_sum
    FROM sales_base sb
    FULL OUTER JOIN returns_catalog rc
        ON sb.ss_sold_time_sk = rc.cr_returned_time_sk
       AND sb.ss_item_sk      = rc.cr_item_sk
    LEFT JOIN returns_web rw
        ON sb.ss_customer_sk = rw.wr_refunded_customer_sk
       AND sb.ss_sold_time_sk = rw.wr_returned_time_sk
    CROSS JOIN UNNEST(sb.measures_array) AS t(measure_value)
    WHERE sb.i_current_price > (SELECT AVG(i_current_price) FROM item)   -- uncorrelated scalar subquery comparison
    GROUP BY
        sb.s_store_name,
        sb.i_category,
        sb.ss_customer_sk,
        sb.i_brand
)
SELECT *
FROM main_query
EXCEPT
SELECT *
FROM main_query
WHERE total_sales_amount < 0
ORDER BY total_sales_amount DESC
OFFSET 0 LIMIT 100
