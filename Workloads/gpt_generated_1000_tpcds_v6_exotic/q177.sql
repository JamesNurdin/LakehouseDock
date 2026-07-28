WITH base_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_reason_sk,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_college_count,
        w.w_state,
        w.w_county
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_college_count >= 2
      AND cp.cp_department = 'Electronics'
      AND w.w_county = 'Fairfield County'
      AND cr.cr_return_amount > 100.00
      AND ss.ss_ext_discount_amt BETWEEN 50 AND 2000
)
SELECT
    w_state,
    cp_department,
    cd_gender,
    CASE
        WHEN cr_return_amount > 500 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    COUNT(*) AS txn_count,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(ss_ext_discount_amt) AS avg_discount_amt,
    MIN(ss_net_paid) AS min_net_paid,
    MAX(ss_net_paid) AS max_net_paid
FROM base_data
GROUP BY
    w_state,
    cp_department,
    cd_gender,
    CASE
        WHEN cr_return_amount > 500 THEN 'High'
        ELSE 'Low'
    END
ORDER BY total_return_amount DESC
LIMIT 100
