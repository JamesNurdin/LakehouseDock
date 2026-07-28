WITH store_ret AS (
    SELECT r.r_reason_desc AS reason_desc,
           i.i_category AS category,
           sr.sr_net_loss AS net_loss,
           1 AS cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_category = 'Sports'
),
web_ret AS (
    SELECT r.r_reason_desc AS reason_desc,
           i.i_category AS category,
           wr.wr_net_loss AS net_loss,
           1 AS cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_category = 'Sports'
),
combined AS (
    SELECT reason_desc, category, net_loss, cnt FROM store_ret
    UNION ALL
    SELECT reason_desc, category, net_loss, cnt FROM web_ret
)
SELECT reason_desc,
       category,
       SUM(net_loss) AS total_net_loss,
       SUM(cnt) AS total_returns
FROM combined
GROUP BY reason_desc, category
ORDER BY total_net_loss DESC
LIMIT 10
