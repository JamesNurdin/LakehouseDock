WITH inv_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    s.s_market_id,
    s.s_market_desc,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(inv_agg.total_qty_on_hand) AS avg_inventory_qty,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(AVG(inv_agg.total_qty_on_hand), 0), 2) AS return_to_inventory_ratio,
    MAX(d.d_date) AS latest_return_date,
    MIN(d.d_date) AS earliest_return_date,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cr.cr_return_amount) DESC) AS category_rank_by_return
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk AND inv_agg.inv_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_market_desc IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    s.s_market_id,
    s.s_market_desc
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
