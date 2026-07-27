WITH cr_base AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_item_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk
    FROM catalog_returns cr
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = cr.cr_item_sk
          AND sr.sr_return_quantity > 5
    )
),
joined AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        t_cr.t_meal_time,
        cr_base.cr_net_loss,
        cr_base.cr_item_sk
    FROM cr_base
    -- join to warehouse (1)
    JOIN warehouse w
        ON cr_base.cr_warehouse_sk = w.w_warehouse_sk
    -- first join to time_dim for the catalog return time (2)
    JOIN time_dim t_cr
        ON cr_base.cr_returned_time_sk = t_cr.t_time_sk
    -- second join to the same time_dim under a different alias (3)
    JOIN time_dim t_cr_extra
        ON cr_base.cr_returned_time_sk = t_cr_extra.t_time_sk
    -- join to customer_address for the refunded address (4)
    JOIN customer_address ca_ref
        ON cr_base.cr_refunded_addr_sk = ca_ref.ca_address_sk
    -- join to customer_address for the returning address (5)
    JOIN customer_address ca_ret
        ON cr_base.cr_returning_addr_sk = ca_ret.ca_address_sk
    -- another join to customer_address using the refunded address again under a new alias (6)
    JOIN customer_address ca_ref2
        ON cr_base.cr_refunded_addr_sk = ca_ref2.ca_address_sk
    -- join to store_returns via the time dimension we already have (7)
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t_cr.t_time_sk
    -- join to customer_address for the store return address (8)
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    -- second join to time_dim for the store return time under a new alias (9)
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE w.w_zip LIKE '7%'
),
agg AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        t_meal_time,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr_item_sk) AS distinct_items_returned
    FROM joined
    GROUP BY w_warehouse_sk, w_warehouse_name, t_meal_time
)
SELECT
    w_warehouse_name,
    t_meal_time,
    total_net_loss,
    distinct_items_returned,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_sk ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
