/* goal: Determine which brand within each product category generates the highest return amount, while filtering for recent items, reasonable wholesale cost, active inventory, and significant return fees. The query aggregates returns per brand, applies a HAVING filter, then computes category‑wide totals and ranking via window functions. */
WITH joined_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_wholesale_cost,
        inv.inv_quantity_on_hand,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_fee,
        i.i_item_sk
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_rec_end_date > DATE '1999-12-31'
      AND i.i_wholesale_cost > 0.50
      AND inv.inv_quantity_on_hand > 0
      AND sr.sr_fee > 20
),
agg_by_category_brand AS (
    SELECT
        i_category,
        i_brand,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty,
        AVG(i_wholesale_cost) AS avg_wholesale_cost,
        SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM joined_data
    GROUP BY i_category, i_brand
    HAVING SUM(sr_return_amt) > 1000
       AND SUM(sr_return_quantity) > 10
)
SELECT
    i_category,
    i_brand,
    total_return_amt,
    total_return_qty,
    avg_wholesale_cost,
    total_inventory_qty,
    SUM(total_return_amt) OVER (PARTITION BY i_category) AS category_total_return_amt,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank
FROM agg_by_category_brand
ORDER BY total_return_amt DESC
LIMIT 100
