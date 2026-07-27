WITH reason_agg AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_id,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) FILTER (WHERE sr.sr_net_loss IS NOT NULL) AS store_return_cnt,
        COUNT(*) FILTER (WHERE wr.wr_net_loss IS NOT NULL) AS web_return_cnt
    FROM tpcds.reason r
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_sk IN (3, 7, 12, 16)                     -- predicate 1
      AND sr.sr_store_credit > 10                              -- predicate 2
      AND sr.sr_cdemo_sk IN (84914, 463971)                    -- predicate 3
      AND wr.wr_reversed_charge > 20                          -- predicate 4
      AND wr.wr_return_ship_cost < 200                         -- predicate 5
      AND wr.wr_returning_addr_sk = 1854347                    -- predicate 6
    GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    r.store_net_loss,
    r.web_net_loss,
    r.total_net_loss,
    CASE
        WHEN r.total_net_loss > 1000 THEN 'High'
        WHEN r.total_net_loss > 500  THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (ORDER BY r.total_net_loss DESC) AS loss_rank
FROM reason_agg r
ORDER BY loss_rank
LIMIT 100
