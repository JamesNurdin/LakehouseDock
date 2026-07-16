WITH store_ret_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        c.c_current_addr_sk AS address_sk,
        ca.ca_state AS state,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_ship_cost) AS total_ship_cost,
        'store' AS return_type,
        NULL AS ship_mode,
        NULL AS warehouse_name
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451080
    GROUP BY sr.sr_customer_sk, c.c_current_addr_sk, ca.ca_state
),
catalog_ret_agg AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        c.c_current_addr_sk AS address_sk,
        ca.ca_state AS state,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        'catalog' AS return_type,
        sm.sm_carrier AS ship_mode,
        w.w_warehouse_name AS warehouse_name
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451080
    GROUP BY cr.cr_returning_customer_sk, c.c_current_addr_sk, ca.ca_state, sm.sm_carrier, w.w_warehouse_name
),
all_returns AS (
    SELECT * FROM store_ret_agg
    UNION ALL
    SELECT * FROM catalog_ret_agg
)
SELECT
    customer_sk,
    address_sk,
    state,
    SUM(total_net_loss) AS total_net_loss,
    SUM(total_return_amount) / NULLIF(SUM(return_cnt), 0) AS avg_return_amount,
    SUM(return_cnt) AS total_returns,
    SUM(total_ship_cost) / NULLIF(SUM(return_cnt), 0) AS avg_ship_cost,
    COUNT(DISTINCT return_type) AS return_types,
    MAX(ship_mode) AS ship_mode,
    MAX(warehouse_name) AS warehouse_name
FROM all_returns
GROUP BY customer_sk, address_sk, state
HAVING SUM(return_cnt) >= 5
ORDER BY total_net_loss DESC
LIMIT 10
