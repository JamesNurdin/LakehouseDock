WITH filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_class,
        cc.cc_employees,
        cc.cc_gmt_offset,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_ship_mode_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_tax,
        cr.cr_net_loss
    FROM tpcds.call_center cc
    FULL OUTER JOIN tpcds.catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
        cc.cc_class = 'large' AND
        cc.cc_employees > 200 AND
        cc.cc_gmt_offset >= -5.0 AND
        cr.cr_return_amount > 100.00 AND
        cr.cr_return_quantity >= 2 AND
        cr.cr_ship_mode_sk IN (11, 2, 5)
)
SELECT
    fc.cc_call_center_id,
    fc.cc_name,
    fc.cc_class,
    fc.cc_employees,
    fc.cr_return_amount,
    fc.cr_return_quantity,
    fc.cr_ship_mode_sk,
    CASE 
        WHEN fc.cr_return_amount > avg_ret.avg_return_amount THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_amount_category,
    RANK() OVER (PARTITION BY fc.cc_class ORDER BY fc.cr_return_amount DESC) AS return_amount_rank,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_call_center_sk = fc.cc_call_center_sk
    ) AS max_center_return_amount
FROM filtered fc
CROSS JOIN (
    SELECT AVG(cr_return_amount) AS avg_return_amount
    FROM tpcds.catalog_returns
) avg_ret
ORDER BY return_amount_rank, fc.cc_call_center_id
LIMIT 100
