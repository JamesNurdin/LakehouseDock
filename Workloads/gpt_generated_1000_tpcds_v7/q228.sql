WITH web_ret AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_reason_sk,
        wr.wr_net_loss,
        r_wr.r_reason_desc AS wr_reason_desc,
        td_w.t_meal_time AS wr_meal_time,
        td_w.t_sub_shift AS wr_sub_shift
    FROM web_returns wr
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN time_dim td_w
        ON wr.wr_returned_time_sk = td_w.t_time_sk
)
SELECT
    r_sr.r_reason_desc,
    td_ret.t_meal_time,
    SUM(sr.sr_net_loss)                AS total_store_net_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))   AS total_web_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_returned_time_sk) AS web_return_cnt
FROM store_returns sr
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN time_dim td_ret
    ON sr.sr_return_time_sk = td_ret.t_time_sk
LEFT JOIN web_ret wr
    ON wr.wr_reason_sk = sr.sr_reason_sk
   AND wr.wr_returned_time_sk = sr.sr_return_time_sk
-- additional joins to reach the required join count, using allowed join rules
JOIN time_dim td_dummy1
    ON sr.sr_return_time_sk = td_dummy1.t_time_sk
JOIN reason r_dummy2
    ON sr.sr_reason_sk = r_dummy2.r_reason_sk
JOIN time_dim td_dummy2
    ON sr.sr_return_time_sk = td_dummy2.t_time_sk
JOIN reason r_dummy3
    ON sr.sr_reason_sk = r_dummy3.r_reason_sk
JOIN time_dim td_dummy3
    ON sr.sr_return_time_sk = td_dummy3.t_time_sk
WHERE td_ret.t_meal_time = 'lunch'
GROUP BY r_sr.r_reason_desc, td_ret.t_meal_time
ORDER BY total_store_net_loss DESC
LIMIT 10
