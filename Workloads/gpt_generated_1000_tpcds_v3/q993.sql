WITH inv_daily AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
joined AS (
    SELECT
        sr.sr_returned_date_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        sr.sr_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_gmt_offset,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        inv.total_quantity_on_hand,
        inv.avg_quantity_on_hand,
        d_cl.d_year AS store_closed_year
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_cl
        ON s.s_closed_date_sk = d_cl.d_date_sk
    LEFT JOIN inv_daily inv
        ON sr.sr_returned_date_sk = inv.inv_date_sk
),
agg AS (
    SELECT
        j.s_store_name,
        j.s_state,
        j.d_year,
        j.sr_item_sk,
        SUM(j.sr_return_quantity) AS total_return_qty,
        SUM(j.sr_net_loss) AS total_net_loss,
        AVG(j.avg_quantity_on_hand) AS avg_inventory_quantity,
        MAX(j.total_quantity_on_hand) AS total_quantity_on_hand
    FROM joined j
    WHERE j.d_year = 2002
      AND j.s_state = 'CA'
      AND j.total_quantity_on_hand > 500
      AND j.sr_return_quantity > 5
    GROUP BY j.s_store_name, j.s_state, j.d_year, j.sr_item_sk, j.total_quantity_on_hand
)
SELECT
    a.s_store_name,
    a.s_state,
    a.d_year,
    a.sr_item_sk,
    a.total_return_qty,
    a.total_net_loss,
    a.avg_inventory_quantity,
    CASE
        WHEN a.total_net_loss > (
            SELECT AVG(inner_a.total_net_loss)
            FROM agg inner_a
            WHERE inner_a.d_year = a.d_year
        ) THEN 'Above Avg Yearly'
        ELSE 'Below Avg Yearly'
    END AS net_loss_category,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM agg a
ORDER BY a.d_year, net_loss_rank
LIMIT 100
