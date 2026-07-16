WITH daily_store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND s.s_state = 'TX'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_date,
        d.d_year,
        d.d_month_seq
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    dsa.s_store_id,
    dsa.s_store_name,
    dsa.s_city,
    dsa.s_state,
    dsa.d_date,
    dsa.d_year,
    dsa.d_month_seq,
    dsa.total_return_amount,
    dsa.total_return_qty,
    dsa.total_net_loss,
    dsa.total_inventory_on_hand,
    dsa.avg_inventory_on_hand,
    dsa.distinct_items_returned,
    CAST(dsa.total_return_qty AS DOUBLE) / NULLIF(dsa.total_inventory_on_hand, 0) AS return_to_inventory_ratio,
    CAST(dsa.total_return_amount AS DOUBLE) / NULLIF(dsa.total_inventory_on_hand, 0) AS avg_return_amount_per_inventory,
    ROW_NUMBER() OVER (PARTITION BY dsa.s_store_id ORDER BY dsa.d_date) AS store_date_rank,
    SUM(dsa.total_return_amount) OVER (PARTITION BY dsa.s_store_id ORDER BY dsa.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount
FROM daily_store_agg dsa
ORDER BY dsa.s_store_id, dsa.d_date
