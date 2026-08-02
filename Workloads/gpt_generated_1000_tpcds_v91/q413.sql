WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reversed_charge,
        cr.cr_net_loss,
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_returned_time_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        i.i_manufact_id,
        i.i_container,
        i.i_manufact,
        sm.sm_type,
        t.t_second,
        c_ref.c_customer_id AS refunded_cust_id,
        c_ret.c_customer_id AS returning_cust_id,
        (
            SELECT MAX(i_sub.i_current_price)
            FROM item i_sub
            WHERE i_sub.i_item_sk = cr.cr_item_sk
        ) AS max_price_for_item
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    LEFT JOIN customer c_ret
        ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    WHERE
        (cr.cr_return_amount > 20.00 OR cr.cr_return_amount IS NULL)
        AND (cr.cr_return_quantity >= 1 OR cr.cr_return_quantity IS NULL)
        AND (cr.cr_reversed_charge > 10.00 OR cr.cr_reversed_charge IS NULL)
        AND (i.i_manufact_id IN (167, 995, 630) OR i.i_manufact_id IS NULL)
        AND (i.i_container = 'Unknown' OR i.i_container IS NULL)
        AND (t.t_second IN (0, 3, 12) OR t.t_second IS NULL)
        AND EXISTS (
            SELECT 1
            FROM item i_check
            WHERE i_check.i_item_sk = cr.cr_item_sk
              AND i_check.i_manufact_id = 86
        )
),
agg_data AS (
    SELECT
        i_manufact_id,
        sm_type,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cr_return_amount) AS total_return_amount,
        CASE
            WHEN SUM(cr_return_amount) > 1000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS return_volume_category,
        MAX(max_price_for_item) AS max_price_for_item
    FROM joined_data
    GROUP BY ROLLUP (i_manufact_id, sm_type)
    HAVING SUM(cr_net_loss) IS NOT NULL
)
SELECT
    COALESCE(i_manufact_id, -1) AS manufact_id,
    COALESCE(sm_type, 'UNKNOWN') AS ship_mode,
    total_net_loss,
    total_return_amount,
    return_volume_category,
    max_price_for_item,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(sm_type, 'UNKNOWN')
        ORDER BY total_net_loss DESC
    ) AS rn
FROM agg_data
ORDER BY total_net_loss DESC
LIMIT 100
