WITH wr_agg AS (
    SELECT
        wr_item_sk,
        wr_returned_time_sk,
        wr_reason_sk,
        SUM(wr_net_loss) AS total_wr_net_loss,
        COUNT(*) AS wr_return_cnt
    FROM web_returns
    WHERE wr_return_amt > 20
    GROUP BY wr_item_sk, wr_returned_time_sk, wr_reason_sk
)
SELECT
    i1.i_brand,
    t1.t_hour,
    r1.r_reason_desc,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr_agg.total_wr_net_loss) AS web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    SUM(wr_agg.wr_return_cnt) AS web_return_cnt
FROM catalog_returns cr
JOIN item i1
    ON cr.cr_item_sk = i1.i_item_sk
JOIN reason r1
    ON cr.cr_reason_sk = r1.r_reason_sk
JOIN time_dim t1
    ON cr.cr_returned_time_sk = t1.t_time_sk
JOIN wr_agg
    ON cr.cr_item_sk = wr_agg.wr_item_sk
   AND cr.cr_returned_time_sk = wr_agg.wr_returned_time_sk
JOIN item i2
    ON wr_agg.wr_item_sk = i2.i_item_sk
JOIN reason r2
    ON wr_agg.wr_reason_sk = r2.r_reason_sk
JOIN time_dim t2
    ON wr_agg.wr_returned_time_sk = t2.t_time_sk
-- additional joins using separate aliases of the same dimension tables
JOIN item i3
    ON i1.i_item_id = i3.i_item_id
JOIN reason r3
    ON r1.r_reason_id = r3.r_reason_id
JOIN time_dim t3
    ON t1.t_time_id = t3.t_time_id
GROUP BY
    i1.i_brand,
    t1.t_hour,
    r1.r_reason_desc
ORDER BY web_net_loss DESC
LIMIT 100
