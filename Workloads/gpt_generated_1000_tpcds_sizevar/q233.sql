WITH sr_agg AS (
    SELECT
        sr_store_sk,
        sr_reason_sk,
        sr_hdemo_sk,
        sr_return_time_sk,
        SUM(sr_net_loss)      AS total_net_loss,
        COUNT(*)              AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_store_sk, sr_reason_sk, sr_hdemo_sk, sr_return_time_sk
),
wr_agg AS (
    SELECT
        wr_reason_sk,
        wr_returned_time_sk,
        wr_refunded_hdemo_sk,
        wr_returning_hdemo_sk,
        SUM(wr_net_loss)      AS total_wr_net_loss,
        COUNT(*)              AS wr_return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_reason_sk, wr_returned_time_sk, wr_refunded_hdemo_sk, wr_returning_hdemo_sk
),
joined AS (
    SELECT
        s.s_store_id,
        r.r_reason_id,
        hd.hd_vehicle_count,
        td.t_hour,
        sr_agg.total_net_loss,
        sr_agg.return_cnt,
        wr_agg.total_wr_net_loss,
        wr_agg.wr_return_cnt,
        (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = r.r_reason_sk
        ) AS avg_return_amt_by_reason
    FROM sr_agg
    JOIN store s           ON sr_agg.sr_store_sk       = s.s_store_sk
    JOIN reason r          ON sr_agg.sr_reason_sk      = r.r_reason_sk
    JOIN time_dim td       ON sr_agg.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd ON sr_agg.sr_hdemo_sk = hd.hd_demo_sk
    -- duplicate join to the same dimension under a different alias
    JOIN reason r_extra    ON sr_agg.sr_reason_sk      = r_extra.r_reason_sk
    -- bring in web‑returns aggregates
    JOIN wr_agg            ON wr_agg.wr_reason_sk      = r.r_reason_sk
    JOIN reason r_web      ON wr_agg.wr_reason_sk      = r_web.r_reason_sk
    JOIN time_dim td_web   ON wr_agg.wr_returned_time_sk = td_web.t_time_sk
    JOIN household_demographics hd_ref ON wr_agg.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON wr_agg.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE s.s_store_id NOT IN (
        SELECT s2.s_store_id
        FROM store s2
        WHERE s2.s_state = 'CA'
    )
)
SELECT
    s_store_id,
    r_reason_id,
    MAX(hd_vehicle_count)                AS max_vehicle_count,
    MAX(t_hour)                           AS sample_hour,
    SUM(total_net_loss)                   AS sum_store_net_loss,
    SUM(return_cnt)                       AS sum_store_return_cnt,
    SUM(total_wr_net_loss)                AS sum_web_net_loss,
    SUM(wr_return_cnt)                    AS sum_web_return_cnt,
    MAX(avg_return_amt_by_reason)         AS avg_return_amt_by_reason,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(total_net_loss) DESC) AS loss_rank
FROM joined
GROUP BY ROLLUP (s_store_id, r_reason_id)
ORDER BY s_store_id NULLS LAST, r_reason_id NULLS LAST
LIMIT 100
