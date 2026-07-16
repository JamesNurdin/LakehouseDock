WITH
store_agg AS (
    SELECT
        r.r_reason_desc,
        c.c_current_cdemo_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt,
        AVG(sr.sr_return_quantity) AS avg_store_return_qty
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year >= 1950
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450365
    GROUP BY r.r_reason_desc, c.c_current_cdemo_sk
),
web_agg AS (
    SELECT
        r.r_reason_desc,
        c.c_current_cdemo_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year >= 1950
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450365
    GROUP BY r.r_reason_desc, c.c_current_cdemo_sk
),
combined AS (
    SELECT
        COALESCE(s.r_reason_desc, w.r_reason_desc) AS reason_desc,
        COALESCE(s.c_current_cdemo_sk, w.c_current_cdemo_sk) AS cdemo_sk,
        COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(s.store_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        (COALESCE(s.avg_store_return_qty, 0) * COALESCE(s.store_return_cnt, 0) +
         COALESCE(w.avg_web_return_qty, 0) * COALESCE(w.web_return_cnt, 0)) AS weighted_qty_sum,
        (COALESCE(s.store_return_cnt, 0) + COALESCE(w.web_return_cnt, 0)) AS total_cnt
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.r_reason_desc = w.r_reason_desc
        AND s.c_current_cdemo_sk = w.c_current_cdemo_sk
)
SELECT
    reason_desc,
    cdemo_sk,
    total_net_loss,
    total_return_cnt,
    weighted_qty_sum / total_cnt AS avg_return_quantity,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM combined
WHERE total_return_cnt > 10
ORDER BY total_net_loss DESC
LIMIT 50
