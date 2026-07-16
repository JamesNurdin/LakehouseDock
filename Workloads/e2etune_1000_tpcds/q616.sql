WITH filtered_inventory AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_date_sk BETWEEN 2450000 AND 2450150
),
item_with_band AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_wholesale_cost,
           i.i_current_price,
           ib.ib_income_band_sk
    FROM item i
    JOIN income_band ib
      ON i.i_wholesale_cost BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE i.i_current_price > 20.00
),
agg AS (
    SELECT
        iw.i_category,
        iw.ib_income_band_sk,
        SUM(fi.inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(iw.i_wholesale_cost) AS avg_wholesale_cost
    FROM filtered_inventory fi
    JOIN item_with_band iw
      ON fi.inv_item_sk = iw.i_item_sk
    GROUP BY iw.i_category, iw.ib_income_band_sk
    HAVING SUM(fi.inv_quantity_on_hand) > 0
)
SELECT
    a.i_category,
    a.ib_income_band_sk,
    a.total_quantity_on_hand,
    a.avg_wholesale_cost,
    RANK() OVER (PARTITION BY a.ib_income_band_sk ORDER BY a.total_quantity_on_hand DESC) AS quantity_rank
FROM agg a
ORDER BY a.ib_income_band_sk, quantity_rank
