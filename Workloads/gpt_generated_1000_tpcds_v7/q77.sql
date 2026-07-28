WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        ss.ss_ext_sales_price,
        cr.cr_return_amount,
        w.w_state,
        sm.sm_type,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ss.ss_sold_time_sk IN (56996, 31022)
      AND c.c_birth_year BETWEEN 1950 AND 1960
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND (cr.cr_return_amount > 10 OR cr.cr_return_amount IS NULL)
      AND (inv.inv_quantity_on_hand > 200 OR inv.inv_quantity_on_hand IS NULL)
),
aggregated AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
        AVG(COALESCE(cr_return_amount, 0)) AS avg_return_amount
    FROM base
    GROUP BY cd_gender, cd_marital_status
)
SELECT
    cd_gender,
    cd_marital_status,
    num_customers,
    total_sales,
    total_returns,
    avg_return_amount,
    total_sales / NULLIF(num_customers, 0) AS avg_sales_per_customer
FROM aggregated
WHERE total_sales > 1000
ORDER BY total_sales DESC
LIMIT 100
