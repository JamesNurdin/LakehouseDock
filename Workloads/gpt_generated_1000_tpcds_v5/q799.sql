WITH
q1 AS (
    SELECT
        cc.cc_name,
        td_ws.t_hour,
        cd_bill.cd_gender,
        SUM(ws.ws_net_paid_inc_ship) AS total_paid,
        SUM(cr.cr_return_amount) AS total_return,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        (SELECT MAX(cc2.cc_gmt_offset) FROM call_center cc2) AS max_gmt_offset
    FROM
        catalog_returns cr
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd_ref
            ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN time_dim td_cr
            ON cr.cr_returned_time_sk = td_cr.t_time_sk
        JOIN web_sales ws
            ON cr.cr_order_number = ws.ws_order_number
        JOIN time_dim td_ws
            ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN customer_demographics cd_bill
            ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    WHERE
        cc.cc_state = 'CA'
        AND td_ws.t_hour BETWEEN 8 AND 12
        AND cd_bill.cd_gender = 'M'
        AND ws.ws_ext_ship_cost > 1000
        AND cd_ref.cd_purchase_estimate > 3000
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = ws.ws_order_number
              AND cr2.cr_return_amount > 500
        )
    GROUP BY
        cc.cc_name,
        td_ws.t_hour,
        cd_bill.cd_gender
),
q2 AS (
    SELECT
        cc.cc_name,
        td_ws.t_hour,
        cd_bill.cd_gender,
        SUM(ws.ws_net_paid_inc_ship) AS total_paid,
        SUM(cr.cr_return_amount) AS total_return,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        (SELECT MAX(cc2.cc_gmt_offset) FROM call_center cc2) AS max_gmt_offset
    FROM
        catalog_returns cr
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd_ref
            ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN time_dim td_cr
            ON cr.cr_returned_time_sk = td_cr.t_time_sk
        JOIN web_sales ws
            ON cr.cr_order_number = ws.ws_order_number
        JOIN time_dim td_ws
            ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN customer_demographics cd_bill
            ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    WHERE
        cc.cc_state = 'TX'
        AND td_ws.t_hour BETWEEN 13 AND 18
        AND cd_bill.cd_gender = 'F'
        AND ws.ws_ext_ship_cost > 1500
        AND cd_ref.cd_purchase_estimate > 4000
    GROUP BY
        cc.cc_name,
        td_ws.t_hour,
        cd_bill.cd_gender
)
SELECT *
FROM (
    SELECT * FROM q1
    UNION ALL
    SELECT * FROM q2
) combined
ORDER BY total_paid DESC
LIMIT 100
