WITH
    store_agg AS (
        SELECT
            sr_addr_sk,
            SUM(sr_return_amt) AS total_sr_return_amt,
            COUNT(*) AS cnt_sr
        FROM store_returns
        GROUP BY sr_addr_sk
    ),
    web_agg AS (
        SELECT
            ws_ship_mode_sk,
            SUM(ws_net_profit) AS total_ws_profit,
            COUNT(*) AS cnt_ws
        FROM web_sales
        GROUP BY ws_ship_mode_sk
    )
SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    CASE
        WHEN cr.cr_return_amount > (
            SELECT MAX(cr_return_amount)
            FROM catalog_returns
            WHERE cr_ship_mode_sk = 2
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_category,
    ca_refunded.ca_state               AS refunded_state,
    ca_returning.ca_city               AS returning_city,
    sm_cr.sm_type                      AS ship_mode_type,
    store_agg.total_sr_return_amt,
    web_agg.total_ws_profit,
    (
        SELECT COUNT(*)
        FROM (
            SELECT cr_order_number FROM catalog_returns
            INTERSECT
            SELECT ws_order_number FROM web_sales
        ) intersected
    ) AS intersect_order_cnt,
    (
        SELECT COUNT(*)
        FROM (
            SELECT cr_item_sk FROM catalog_returns
            EXCEPT
            SELECT sr_item_sk FROM store_returns
        ) diffed
    ) AS diff_item_cnt
FROM catalog_returns cr
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN store_agg
    ON store_agg.sr_addr_sk = cr.cr_refunded_addr_sk
JOIN store_returns sr
    ON sr.sr_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_sales ws
    ON ws.ws_bill_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_agg
    ON web_agg.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
WHERE cr.cr_item_sk NOT IN (SELECT sr_item_sk FROM store_returns)
GROUP BY
    cr.cr_order_number,
    cr.cr_return_amount,
    ca_refunded.ca_state,
    ca_returning.ca_city,
    sm_cr.sm_type,
    store_agg.total_sr_return_amt,
    web_agg.total_ws_profit
LIMIT 100
