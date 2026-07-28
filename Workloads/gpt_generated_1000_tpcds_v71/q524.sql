/*
Goal: Summarize combined net loss from store and catalog returns by call center and return reason for California call centers, households with more than one vehicle, and the return reason 'Did not get it on time'. Also show the average catalog‑return net loss for each call center.
*/
WITH base AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        r.r_reason_desc,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        cr.cr_net_loss,
        hd.hd_vehicle_count,
        t.t_hour,
        cc.cc_call_center_sk
    FROM
        tpcds.time_dim t
        JOIN tpcds.store_returns sr
            ON sr.sr_return_time_sk = t.t_time_sk
        JOIN tpcds.customer c
            ON sr.sr_customer_sk = c.c_customer_sk
        JOIN tpcds.household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN tpcds.reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN tpcds.catalog_sales cs
            ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN tpcds.call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.catalog_returns cr
            ON cr.cr_returned_time_sk = t.t_time_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_call_center_sk = cc.cc_call_center_sk
            AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            AND cr.cr_reason_sk = r.r_reason_sk
    WHERE
        cc.cc_state = 'CA'
        AND hd.hd_vehicle_count > 1
        AND r.r_reason_desc = 'Did not get it on time'
        AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    b.cc_name,
    b.r_reason_desc,
    COUNT(DISTINCT b.sr_ticket_number) AS store_return_count,
    SUM(b.sr_net_loss) AS total_store_net_loss,
    SUM(b.cr_net_loss) AS total_catalog_net_loss,
    (SUM(b.sr_net_loss) + SUM(b.cr_net_loss)) AS total_combined_net_loss,
    (
        SELECT AVG(cr2.cr_net_loss)
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_call_center_sk = b.cc_call_center_sk
    ) AS avg_catalog_net_loss_per_cc
FROM
    base b
GROUP BY
    b.cc_name,
    b.r_reason_desc,
    b.cc_call_center_sk
HAVING
    (SUM(b.sr_net_loss) + SUM(b.cr_net_loss)) > 10000
ORDER BY
    total_combined_net_loss DESC
