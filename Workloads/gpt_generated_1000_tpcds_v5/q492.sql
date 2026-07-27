WITH joined_data AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_zip,
        w.w_street_type,
        ss.ss_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_net_loss,
        i.inv_quantity_on_hand,
        c.c_birth_month,
        c.c_customer_id
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_month IN (1, 3, 7, 9, 10)               -- predicate 1
        AND w.w_state = 'CA'                               -- predicate 2
        AND w.w_street_type IN ('Parkway', 'Road', 'Ave')  -- predicate 3
        AND w.w_zip LIKE '_____'                           -- predicate 4 (any 5‑digit zip)
        AND cr.cr_return_amount > 0                        -- predicate 5
        AND ss.ss_net_profit > 0                           -- predicate 6
        AND i.inv_quantity_on_hand >= 0                    -- predicate 7
),
agg AS (
    SELECT
        w_warehouse_id,
        w_city,
        w_state,
        SUM(ss_ext_sales_price)      AS total_sales,
        SUM(cr_return_amount)        AS total_returns,
        SUM(cr_store_credit)         AS total_store_credit,
        SUM(cr_net_loss)             AS total_net_loss,
        SUM(inv_quantity_on_hand)    AS total_inventory,
        COUNT(DISTINCT c_customer_id) AS distinct_customers
    FROM joined_data
    GROUP BY w_warehouse_id, w_city, w_state
)
SELECT
    w_warehouse_id,
    w_city,
    w_state,
    total_sales,
    total_returns,
    total_inventory,
    distinct_customers,
    CASE
        WHEN total_store_credit > 500 THEN 'HighCredit'
        ELSE 'LowCredit'
    END AS credit_category,
    total_net_loss / NULLIF(total_sales, 0) AS loss_rate
FROM agg
WHERE
    total_sales      > 10000      -- predicate 8
    AND total_returns > 500        -- predicate 9
    AND distinct_customers >= 10   -- predicate 10
    AND total_inventory > 0        -- predicate 11
    AND total_net_loss > 0         -- predicate 12
    AND (total_net_loss / NULLIF(total_sales, 0)) > 0.01  -- predicate 13
ORDER BY loss_rate DESC, total_sales DESC
