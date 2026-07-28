WITH agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        i.i_class,
        i.i_class_id,
        i.i_product_name,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_quantity,
        COUNT(*) AS return_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_amt_inc_tax > 100
      AND sr.sr_return_quantity >= 10
      AND i.i_formulation LIKE '%olive%'
      AND i.i_category_id IN (4, 6, 8, 9)
    GROUP BY
        i.i_category,
        i.i_category_id,
        i.i_class,
        i.i_class_id,
        i.i_product_name
)
SELECT
    i_category,
    i_category_id,
    i_class,
    i_class_id,
    i_product_name,
    total_return_inc_tax,
    total_net_loss,
    total_quantity,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_loss DESC) AS category_net_loss_rank,
    RANK() OVER (ORDER BY total_return_inc_tax DESC) AS overall_return_amt_rank,
    CASE
        WHEN total_net_loss > 5000 THEN 'High Loss'
        WHEN total_net_loss > 1000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_severity
FROM agg
WHERE total_quantity > 20
ORDER BY i_category, category_net_loss_rank
LIMIT 100
