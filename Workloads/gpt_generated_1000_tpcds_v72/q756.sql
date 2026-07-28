WITH cr_agg AS (
    SELECT
        cr_reason_sk,
        SUM(cr_net_loss)                     AS total_net_loss,
        COUNT(*)                             AS cnt_returns,
        AVG(cr_return_amount)                AS avg_return_amount
    FROM catalog_returns
    WHERE cr_return_ship_cost > 100                -- filter 1
      AND cr_store_credit BETWEEN 0 AND 500        -- filter 2
      AND cr_reversed_charge <> 0                 -- filter 3
    GROUP BY cr_reason_sk
),
base AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        ca.total_net_loss,
        ca.cnt_returns,
        ca.avg_return_amount,
        ws.web_cnt
    FROM cr_agg ca
    JOIN reason r
        ON ca.cr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS web_cnt
        FROM web_returns wr
        WHERE wr.wr_reason_sk = r.r_reason_sk
          AND wr.wr_return_amt > 200               -- filter 4 (inside lateral)
    ) ws
    WHERE r.r_reason_id LIKE 'AAAA%'                -- filter 5
      AND EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_reason_sk = r.r_reason_sk
              AND wr2.wr_return_ship_cost > 500   -- filter 6 (scalar subquery)
            LIMIT 1
        )
),
grp AS (
    SELECT
        r_reason_id,
        r_reason_desc,
        total_net_loss,
        cnt_returns,
        avg_return_amount,
        web_cnt
    FROM base
    GROUP BY GROUPING SETS (
        (r_reason_id, r_reason_desc, total_net_loss, cnt_returns, avg_return_amount, web_cnt),
        (r_reason_id, total_net_loss, cnt_returns, avg_return_amount, web_cnt),
        ()
    )
)
SELECT
    r_reason_id,
    r_reason_desc,
    total_net_loss,
    cnt_returns,
    avg_return_amount,
    web_cnt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM grp
ORDER BY loss_rank
LIMIT 100
