WITH agg_a AS (
    SELECT i.i_manufact AS i_manufact,
           i.i_category AS i_category,
           SUM(wr.wr_net_loss) AS total_loss,
           SUM(wr.wr_return_amt) AS total_return,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 5
    GROUP BY ROLLUP(i.i_manufact, i.i_category)
    HAVING SUM(wr.wr_net_loss) > 1000
), agg_b AS (
    SELECT i.i_manufact AS i_manufact,
           i.i_category AS i_category,
           SUM(wr.wr_net_loss) AS total_loss,
           SUM(wr.wr_return_amt) AS total_return,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost <= 5
    GROUP BY ROLLUP(i.i_manufact, i.i_category)
    HAVING COUNT(*) > 100
)
SELECT
    combined.manufact,
    combined.category,
    combined.total_loss,
    combined.total_return,
    combined.return_cnt,
    SUM(combined.total_loss) OVER (PARTITION BY combined.manufact) AS manuf_total_loss,
    ROW_NUMBER() OVER (ORDER BY combined.total_loss DESC) AS row_num
FROM (
    SELECT i_manufact AS manufact,
           i_category AS category,
           total_loss,
           total_return,
           return_cnt
    FROM agg_a
    UNION ALL
    SELECT i_manufact AS manufact,
           i_category AS category,
           total_loss,
           total_return,
           return_cnt
    FROM agg_b
) AS combined
WHERE combined.manufact IN (
    SELECT i_manufact
    FROM item
    GROUP BY i_manufact
    HAVING COUNT(DISTINCT i_item_sk) >= 10
)
ORDER BY combined.total_loss DESC
LIMIT 100
