WITH
    /* Join catalog_returns to its dimension tables */
    cr_join AS (
        SELECT
            cr.cr_reason_sk,
            cp.cp_department,
            cr.cr_return_amount,
            cr.cr_net_loss,
            cr.cr_order_number,
            r.r_reason_desc,
            sm.sm_type,
            ca1.ca_state,
            hd1.hd_vehicle_count
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca1 ON cr.cr_refunded_addr_sk = ca1.ca_address_sk
        JOIN household_demographics hd1 ON cr.cr_refunded_hdemo_sk = hd1.hd_demo_sk
        WHERE r.r_reason_desc LIKE 'Did not %'
          AND sm.sm_type = 'AIR'
          AND cp.cp_department = 'Electronics'
          AND hd1.hd_vehicle_count >= 0
          AND cr.cr_return_amount > 100
    ),
    /* Join web_returns to its dimension tables */
    wr_join AS (
        SELECT
            wr.wr_reason_sk,
            r.r_reason_desc,
            wr.wr_return_amt_inc_tax,
            wr.wr_net_loss,
            wr.wr_order_number,
            ca2.ca_state AS wr_state,
            hd2.hd_vehicle_count AS wr_vehicle_count
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer_address ca2 ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
        JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
        WHERE r.r_reason_desc LIKE 'Did not %'
          AND hd2.hd_vehicle_count >= 0
          AND wr.wr_return_amt_inc_tax > 100
    )
SELECT
    r.r_reason_desc,
    cr.cp_department,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_returns_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_returns_cnt,
    ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) DESC) AS rn
FROM cr_join cr
JOIN wr_join wr ON cr.cr_reason_sk = wr.wr_reason_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
GROUP BY r.r_reason_desc, cr.cp_department
HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 100
