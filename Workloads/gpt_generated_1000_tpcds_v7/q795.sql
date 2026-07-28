WITH cr_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns
    WHERE cr_return_amount > 50
      AND cr_return_quantity >= 1
      AND cr_refunded_cash < 150
      AND cr_reversed_charge <> 0
    GROUP BY cr_item_sk
)
SELECT
    i.i_brand,
    i.i_color,
    SUM(cr_agg.total_return_amount) AS brand_color_return_amount,
    AVG(cr_agg.total_net_loss) AS avg_net_loss,
    COUNT(*) AS num_items
FROM cr_agg
JOIN tpcds.item i
    ON cr_agg.cr_item_sk = i.i_item_sk
WHERE i.i_wholesale_cost BETWEEN 0.5 AND 20
  AND i.i_manufact_id IN (86, 460)
  AND i.i_color IN ('red', 'turquoise')
  AND i.i_category IS NOT NULL
GROUP BY i.i_brand, i.i_color
HAVING SUM(cr_agg.total_return_amount) > 1000
ORDER BY brand_color_return_amount DESC
LIMIT 100
