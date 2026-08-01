WITH joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        cp_sales.cp_department,
        sm_sales.sm_type AS ship_mode_type,
        w_sales.w_warehouse_name,
        r.r_reason_desc,
        wp.wp_type AS web_page_type
    FROM store_sales ss
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN catalog_page cp_sales
        ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    INNER JOIN ship_mode sm_sales
        ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
    INNER JOIN warehouse w_sales
        ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    INNER JOIN catalog_page cp_return
        ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
    INNER JOIN ship_mode sm_return
        ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
    INNER JOIN warehouse w_return
        ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
),
aggregated AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        cd_gender,
        COUNT(DISTINCT cs_order_number) AS num_catalog_orders,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs_net_profit) AS total_catalog_profit,
        AVG(cs_ext_sales_price) AS avg_catalog_order_val,
        COUNT(DISTINCT cr_order_number) AS num_returns,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_return_loss,
        AVG(cr_return_amount) AS avg_return_amount
    FROM joined_data
    GROUP BY c_customer_id, c_first_name, c_last_name, cd_gender
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    num_catalog_orders,
    total_catalog_sales,
    total_catalog_profit,
    avg_catalog_order_val,
    num_returns,
    total_return_amount,
    total_return_loss,
    avg_return_amount,
    RANK() OVER (ORDER BY total_catalog_profit DESC) AS profit_rank,
    CASE
        WHEN total_catalog_sales > (SELECT AVG(total_catalog_sales) FROM aggregated)
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_category
FROM aggregated
WHERE total_return_loss > (SELECT MAX(total_return_loss) FROM aggregated)
ORDER BY profit_rank
LIMIT 100
