WITH recent_dates AS (
    SELECT d_date_sk
    FROM tpcds.date_dim
    WHERE d_year = 2020
)
SELECT entity_type,
       entity_id,
       total_return_amount,
       related_metric
FROM (
    /* Returns aggregated by Call Center */
    SELECT
        CAST('call_center' AS varchar) AS entity_type,
        cc.cc_call_center_id AS entity_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        (
            SELECT COUNT(DISTINCT cr2.cr_item_sk)
            FROM tpcds.catalog_returns cr2
            JOIN recent_dates rd2 ON cr2.cr_returned_date_sk = rd2.d_date_sk
            WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
        ) AS related_metric
    FROM tpcds.catalog_returns cr
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr3
        WHERE cr3.cr_call_center_sk = cc.cc_call_center_sk
          AND cr3.cr_return_amount > 0
    )
    GROUP BY cc.cc_call_center_id, cc.cc_call_center_sk

    UNION

    /* Returns aggregated by Ship Mode */
    SELECT
        CAST('ship_mode' AS varchar) AS entity_type,
        sm.sm_ship_mode_id AS entity_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        (
            SELECT AVG(cr2.cr_return_quantity)
            FROM tpcds.catalog_returns cr2
            JOIN recent_dates rd2 ON cr2.cr_returned_date_sk = rd2.d_date_sk
            WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
        ) AS related_metric
    FROM tpcds.catalog_returns cr
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_ship_mode_sk
) AS unified_results
ORDER BY total_return_amount DESC,
         entity_type
LIMIT 100
