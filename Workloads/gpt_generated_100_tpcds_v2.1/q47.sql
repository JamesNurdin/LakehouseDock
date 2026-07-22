WITH per_item AS (
    SELECT
        d_inv.d_year,
        i.i_manufact_id,
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS qty_on_hand,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS sales_estimate,
        AVG(p.p_cost) AS avg_promo_cost,
        MIN(d_start.d_date) AS promo_start_date,
        MAX(d_end.d_date) AS promo_end_date
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE
        i.i_manufact_id IN (350, 169)
        AND i.i_wholesale_cost BETWEEN 5 AND 20
        AND p.p_discount_active = 'Y'
        AND d_inv.d_year = 1998
        AND p.p_channel_radio = 'N'
    GROUP BY d_inv.d_year, i.i_manufact_id, i.i_item_id
)
SELECT
    pi.d_year,
    pi.i_manufact_id,
    COUNT(DISTINCT pi.i_item_id) AS distinct_items,
    SUM(pi.qty_on_hand) AS total_qty_on_hand,
    AVG(pi.sales_estimate) AS avg_sales_estimate_per_item,
    AVG(pi.avg_promo_cost) AS avg_of_avg_promo_cost,
    MIN(pi.promo_start_date) AS earliest_promo_start,
    MAX(pi.promo_end_date) AS latest_promo_end
FROM per_item pi
GROUP BY pi.d_year, pi.i_manufact_id
HAVING SUM(pi.qty_on_hand) > 500
ORDER BY avg_sales_estimate_per_item DESC
LIMIT 20
