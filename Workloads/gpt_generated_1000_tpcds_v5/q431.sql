WITH filtered AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_color,
        i.i_manufact_id,
        i.i_rec_start_date,
        i.i_container,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_fee,
        sr.sr_ticket_number
    FROM tpcds.item i
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND i.i_manufact_id IN (350, 479)
      AND i.i_container = 'Unknown'
      AND inv.inv_quantity_on_hand > 200
      AND sr.sr_return_ship_cost BETWEEN 1.00 AND 100.00
      AND sr.sr_fee > 5.00
      AND sr.sr_return_amt > 0
)
SELECT
    filtered.i_brand,
    filtered.i_category,
    filtered.i_color,
    SUM(filtered.sr_return_amt) AS total_return_amount,
    AVG(filtered.sr_fee) AS avg_fee,
    COUNT(filtered.sr_ticket_number) AS return_count,
    MIN(filtered.inv_quantity_on_hand) AS min_qty_on_hand,
    MAX(filtered.sr_return_ship_cost) AS max_ship_cost
FROM filtered
GROUP BY filtered.i_brand, filtered.i_category, filtered.i_color
ORDER BY total_return_amount DESC
LIMIT 100
