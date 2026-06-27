WITH refunded AS (
    SELECT
        ca.ca_state AS state,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        'refunded' AS addr_role
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
),
returning AS (
    SELECT
        ca.ca_state AS state,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        'returning' AS addr_role
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
),
combined AS (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
)
SELECT
    state,
    addr_role,
    COUNT(*) AS num_returns,
    SUM(cr_return_quantity) AS total_return_quantity,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_fee) AS total_fee,
    SUM(cr_return_ship_cost) AS total_ship_cost,
    SUM(cr_refunded_cash) AS total_refunded_cash,
    SUM(cr_reversed_charge) AS total_reversed_charge,
    SUM(cr_store_credit) AS total_store_credit,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    AVG(cr_net_loss) AS avg_net_loss
FROM combined
GROUP BY state, addr_role
ORDER BY total_net_loss DESC
LIMIT 20
