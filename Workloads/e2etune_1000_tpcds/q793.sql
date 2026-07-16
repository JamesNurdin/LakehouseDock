WITH filtered_returns AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2450900
)
SELECT
    cp.cp_department AS department,
    i.i_class AS item_class,
    COUNT(*) AS return_cnt,
    SUM(fr.wr_net_loss) AS total_net_loss,
    AVG(fr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    RANK() OVER (ORDER BY SUM(fr.wr_net_loss) DESC) AS loss_rank
FROM filtered_returns fr
JOIN item i ON fr.wr_item_sk = i.i_item_sk
JOIN catalog_page cp ON fr.wr_returned_date_sk = cp.cp_start_date_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_department = 'DEPARTMENT'
GROUP BY cp.cp_department, i.i_class
HAVING SUM(fr.wr_net_loss) > 1000
ORDER BY loss_rank
LIMIT 20
