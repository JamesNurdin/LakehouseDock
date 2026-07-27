/*
Goal: Identify the top‑performing items for the year 2001 by combining store sales and catalog return information across all TPC‑DS tables, applying multiple business filters, computing profit status with a CASE expression, aggregating metrics, filtering groups with HAVING, and ranking items within each brand.
*/
WITH joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_promo_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_current_price,
        cd.cd_gender,
        p.p_discount_active,
        sm.sm_type,
        d_sales.d_year AS sales_year,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cr.cr_return_amount
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON ss.ss_item_sk = cr.cr_item_sk
    LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    /* Additional joins required by the schema but not needed for the final projection */
    LEFT JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sales.d_year = 2001                                     -- filter 1
      AND i.i_current_price > 20                                    -- filter 2
      AND p.p_discount_active = 'Y'                                 -- filter 3
      AND sm.sm_type = 'AIR'                                        -- filter 4
      AND cd.cd_gender = 'M'                                        -- filter 5
      AND cp.cp_department = 'Sports'                               -- filter 6
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    sales_year,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(cr_return_amount) AS total_returns,
    SUM(ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY i_brand ORDER BY SUM(ss_net_profit) DESC) AS brand_profit_rank
FROM joined_data
GROUP BY i_item_id, i_product_name, i_brand, sales_year
HAVING SUM(ss_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
