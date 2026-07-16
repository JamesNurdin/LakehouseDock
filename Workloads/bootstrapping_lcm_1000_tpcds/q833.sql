WITH inv_agg AS (
    SELECT inv.inv_date_sk,
           AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
           SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk
),
store_agg AS (
    SELECT s.s_closed_date_sk,
           COUNT(*) AS stores_closed
    FROM store s
    GROUP BY s.s_closed_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    inv_agg.avg_qty_on_hand,
    inv_agg.total_qty_on_hand,
    store_agg.stores_closed,
    SUM(CASE WHEN s.s_state = 'CA' THEN cr.cr_return_amount ELSE 0 END) AS ca_return_amount,
    COUNT(*) FILTER (WHERE cr.cr_return_quantity > 1) AS multiple_item_returns
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
JOIN store_agg
    ON store_agg.s_closed_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    ROLLUP(d.d_year, d.d_month_seq, hd_refunded.hd_buy_potential, hd_returning.hd_buy_potential),
    inv_agg.avg_qty_on_hand,
    inv_agg.total_qty_on_hand,
    store_agg.stores_closed
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
