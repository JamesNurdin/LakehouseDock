WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_returned_time_sk,
        cd_refunded.cd_gender AS refunded_gender,
        cd_returning.cd_gender AS returning_gender,
        sm_ship.sm_carrier,
        sm_ship.sm_contract,
        td_cr.t_sub_shift AS cr_sub_shift,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        wp.wp_web_page_id,
        ws_l.max_sales_price,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM store_returns sr2
                WHERE sr2.sr_item_sk = cr.cr_item_sk
                  AND sr2.sr_returned_date_sk = cr.cr_returned_date_sk
            ) THEN 1 ELSE 0
        END AS has_store_return
    FROM catalog_returns cr
    LEFT JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    LEFT JOIN ship_mode sm_ship
        ON cr.cr_ship_mode_sk = sm_ship.sm_ship_mode_sk
    LEFT JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = cr.cr_item_sk
           AND ws.ws_sold_time_sk = cr.cr_returned_time_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd_ws_bill
        ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ws_ship
        ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    CROSS JOIN LATERAL (
        SELECT max(ws2.ws_ext_sales_price) AS max_sales_price
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = cr.cr_item_sk
    ) AS ws_l
    CROSS JOIN LATERAL (
        SELECT t_sub_shift
        FROM time_dim td_lat
        WHERE td_lat.t_time_sk = cr.cr_returned_time_sk
        LIMIT 1
    ) AS td_lat
)
SELECT
    grouping_key,
    sum_return_amount,
    sum_sales_price,
    total_transactions,
    SUM(sum_return_amount) OVER (
        PARTITION BY grouping_key
        ORDER BY sum_sales_price
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_return_amount,
    RANK() OVER (
        PARTITION BY grouping_key
        ORDER BY sum_return_amount DESC
    ) AS rank_by_return
FROM (
    SELECT
        COALESCE(sm_carrier, 'All Carriers') AS grouping_key,
        sm_carrier,
        refunded_gender,
        cr_sub_shift,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(ws_ext_sales_price) AS sum_sales_price,
        COUNT(*) AS total_transactions
    FROM joined
    GROUP BY GROUPING SETS (
        (sm_carrier, refunded_gender, cr_sub_shift),
        (sm_carrier, refunded_gender),
        (sm_carrier),
        ()
    )
) agg
ORDER BY sum_return_amount DESC
LIMIT 100
