WITH per_item_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_manager_id,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM
        web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE
        i.i_current_price BETWEEN 5 AND 15
        AND i.i_manager_id IN (13, 26, 63)
        AND i.i_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        AND wr.wr_return_quantity > 0
        AND wr.wr_return_amt > 0
        AND wr.wr_returning_hdemo_sk IN (2038, 6669, 2285)
    GROUP BY
        i.i_item_id,
        i.i_brand,
        i.i_manager_id
)
SELECT
    manager_id,
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(return_cnt) AS total_returns,
    AVG(avg_return_qty) AS avg_quantity_per_return
FROM (
    SELECT
        i_manager_id AS manager_id,
        total_return_amt,
        return_cnt,
        avg_return_qty
    FROM per_item_agg
) agg_by_manager
GROUP BY manager_id
HAVING AVG(total_return_amt) > 1000
ORDER BY avg_total_return_amt DESC
LIMIT 100
