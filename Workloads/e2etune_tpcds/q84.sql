WITH profit_by_store AS (
    SELECT ss_store_sk,
           SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2459000 AND 2459125
    GROUP BY ss_store_sk
),
loss_by_store_reason AS (
    SELECT sr_store_sk,
           sr_reason_sk,
           SUM(sr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2459000 AND 2459125
    GROUP BY sr_store_sk, sr_reason_sk
),
joined AS (
    SELECT p.ss_store_sk,
           s.s_store_name AS store_name,
           s.s_city AS city,
           s.s_state AS state,
           r.r_reason_desc AS reason_desc,
           l.total_net_loss,
           p.total_net_profit,
           l.return_cnt,
           (l.total_net_loss / NULLIF(p.total_net_profit, 0)) * 100 AS loss_pct
    FROM profit_by_store p
    JOIN loss_by_store_reason l ON p.ss_store_sk = l.sr_store_sk
    JOIN store s ON p.ss_store_sk = s.s_store_sk
    JOIN reason r ON l.sr_reason_sk = r.r_reason_sk
)
SELECT store_name,
       city,
       state,
       reason_desc,
       total_net_loss,
       total_net_profit,
       loss_pct,
       return_cnt,
       RANK() OVER (PARTITION BY store_name ORDER BY loss_pct DESC) AS reason_rank
FROM joined
WHERE loss_pct > 5
ORDER BY store_name, loss_pct DESC
