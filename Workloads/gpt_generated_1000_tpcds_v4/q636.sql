WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_ship_mode_sk,
        cr.cr_catalog_page_sk,
        cp.cp_department,
        sm.sm_code,
        hd.hd_buy_potential,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND sm.sm_code = 'AIR'
      AND hd.hd_buy_potential = '501-1000'
      AND cp.cp_department = 'Electronics'
      AND cr.cr_return_amount > 100.00
)
SELECT
    d_year,
    cp_department,
    sm_code,
    hd_buy_potential,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ss_net_paid) AS total_sales_net_paid,
    COUNT(DISTINCT ss_ticket_number) AS distinct_sales_orders,
    AVG(ss_quantity) AS avg_quantity,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount
FROM base
GROUP BY d_year, cp_department, sm_code, hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
