/*
Goal: Summarize catalog return net loss by product brand and hour of day for returns where the product name contains a sequence of three or more digits and the time identifier starts with 'AAAA'. The query also shows the average on‑hand inventory quantity for the returned items, filters out groups with total net loss ≤ 1000, orders by loss descending and limits to the top 100 rows.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_time_sk,
        cr.cr_net_loss,
        i.i_brand,
        i.i_product_name,
        t.t_hour,
        t.t_time_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '\\d{3,}')
      AND t.t_time_id LIKE 'AAAA%'
)
SELECT
    fr.i_brand,
    fr.t_hour,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(
        (SELECT AVG(inv.inv_quantity_on_hand)
         FROM inventory inv
         WHERE inv.inv_item_sk = fr.cr_item_sk)
    ) AS avg_inventory_qty
FROM filtered_returns fr
GROUP BY fr.i_brand, fr.t_hour
HAVING SUM(fr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
