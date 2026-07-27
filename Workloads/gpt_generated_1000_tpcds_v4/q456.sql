/* goal: Analyze medium‑sized call centers in Barrow County for the year 2001, focusing on returns that occurred during business hours and were shipped via a specific contract. The query aggregates return quantities and amounts by department, item category and a derived center‑size label, and reports the most common ship‑mode type. */
WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_ship_mode_sk,
        d.d_year,
        t.t_hour,
        i.i_category,
        cp.cp_department,
        cc.cc_class,
        cc.cc_county
    FROM catalog_returns cr
    JOIN date_dim d            ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t            ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i                ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_class = 'medium'
      AND cc.cc_county = 'Barrow County'
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
            AND sm.sm_contract = 'A5BYO1qH8HGTTN'
      )
)
SELECT
    d_year,
    cp_department,
    i_category,
    CASE
        WHEN cc_class = 'large' THEN 'Big Center'
        WHEN cc_class = 'medium' THEN 'Mid Center'
        ELSE 'Small Center'
    END AS center_size_category,
    COUNT(DISTINCT cr_order_number)                     AS return_orders,
    SUM(cr_return_quantity)                            AS total_return_qty,
    SUM(cr_return_amount)                              AS total_return_amount,
    AVG(cr_return_amount)                              AS avg_return_amount,
    MIN(cr_return_amount)                              AS min_return_amount,
    MAX(cr_return_amount)                              AS max_return_amount,
    MAX(
        (SELECT sm_type
         FROM ship_mode sm
         WHERE sm.sm_ship_mode_sk = fr.cr_ship_mode_sk)
    )                                                AS ship_mode_type
FROM filtered_returns fr
GROUP BY
    d_year,
    cp_department,
    i_category,
    CASE
        WHEN cc_class = 'large' THEN 'Big Center'
        WHEN cc_class = 'medium' THEN 'Mid Center'
        ELSE 'Small Center'
    END
ORDER BY total_return_amount DESC
LIMIT 100
