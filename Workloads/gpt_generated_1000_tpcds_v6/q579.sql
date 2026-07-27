WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        td.t_shift,
        cp.cp_department,
        cp.cp_catalog_page_number,
        w.w_city
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_shift = 'first'
      AND cp.cp_catalog_page_number = 15
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451200
      AND w.w_street_type = 'Ave'
      AND w.w_country = 'United States'
      AND cr.cr_return_amount > 100.00
      AND cr.cr_return_quantity >= 2
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
            AND cr2.cr_return_amount > 200.00
      )
)
SELECT
    cp_department,
    t_shift,
    w_city,
    cp_catalog_page_number,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt,
    MIN(cr_returned_date_sk) AS earliest_return_date_sk,
    MAX(cr_returned_date_sk) AS latest_return_date_sk
FROM filtered_returns
GROUP BY
    cp_department,
    t_shift,
    w_city,
    cp_catalog_page_number
ORDER BY total_return_amount DESC
LIMIT 100
