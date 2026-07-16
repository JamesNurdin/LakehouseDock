WITH agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS inventory_rows,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        AVG(i.inv_quantity_on_hand) AS avg_quantity,
        approx_percentile(i.inv_quantity_on_hand, 0.5) AS median_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    JOIN income_band ib
        ON i.inv_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE i.inv_date_sk IN (2450815, 2451046, 2450927)
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    agg.ib_income_band_sk,
    agg.ib_lower_bound,
    agg.ib_upper_bound,
    agg.inventory_rows,
    agg.total_quantity,
    agg.avg_quantity,
    agg.median_quantity,
    agg.distinct_items,
    RANK() OVER (ORDER BY agg.total_quantity DESC) AS total_qty_rank
FROM agg
ORDER BY total_qty_rank
LIMIT 10
