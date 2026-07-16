WITH band_inventory AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        AVG(i.inv_quantity_on_hand) AS avg_quantity
    FROM inventory i
    JOIN income_band ib
      ON i.inv_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE i.inv_date_sk >= 20230101
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING COUNT(*) > 10
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    distinct_items,
    total_quantity,
    avg_quantity,
    RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
FROM band_inventory
ORDER BY total_quantity DESC
LIMIT 10
