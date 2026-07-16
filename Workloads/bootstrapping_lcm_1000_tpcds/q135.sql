WITH inv_agg AS (
    SELECT
        inv_date_sk,
        sum(inv_quantity_on_hand) AS total_inventory_qty,
        avg(inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory
    GROUP BY inv_date_sk
),
store_agg AS (
    SELECT
        s_closed_date_sk,
        count(*) AS stores_closed,
        approx_distinct(s_store_sk) AS distinct_stores_closed,
        min(s_store_name) AS example_store_name
    FROM store
    GROUP BY s_closed_date_sk
)
SELECT
    dd.d_date AS return_date,
    dd.d_year,
    dd.d_month_seq,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    sum(cr.cr_net_loss) AS total_net_loss,
    sum(cr.cr_return_quantity) AS total_return_quantity,
    sum(cr.cr_return_amount) AS total_return_amount,
    inv_agg.total_inventory_qty,
    inv_agg.avg_inventory_qty,
    store_agg.stores_closed,
    store_agg.distinct_stores_closed,
    store_agg.example_store_name
FROM catalog_returns cr
JOIN date_dim dd
    ON cr.cr_returned_date_sk = dd.d_date_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_date_sk = dd.d_date_sk
LEFT JOIN store_agg
    ON store_agg.s_closed_date_sk = dd.d_date_sk
GROUP BY
    dd.d_date,
    dd.d_year,
    dd.d_month_seq,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_buy_potential,
    inv_agg.total_inventory_qty,
    inv_agg.avg_inventory_qty,
    store_agg.stores_closed,
    store_agg.distinct_stores_closed,
    store_agg.example_store_name
ORDER BY total_net_loss DESC
LIMIT 100
