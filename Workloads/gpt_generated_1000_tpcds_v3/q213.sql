WITH store_agg AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(sr_return_tax) AS total_store_return_tax,
        SUM(sr_refunded_cash) AS total_store_refunded_cash,
        SUM(sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_return_tax > 5
    GROUP BY sr_reason_sk
),
web_agg AS (
    SELECT
        wr_reason_sk,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_return_tax) AS total_web_return_tax,
        SUM(wr_refunded_cash) AS total_web_refunded_cash,
        SUM(wr_net_loss) AS total_web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 1
      AND wr_return_tax > 5
    GROUP BY wr_reason_sk
),
reason_agg AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        COALESCE(s.total_store_return_amt, 0) AS total_store_return_amt,
        COALESCE(w.total_web_return_amt, 0) AS total_web_return_amt,
        COALESCE(s.store_return_cnt, 0) AS store_return_cnt,
        COALESCE(w.web_return_cnt, 0) AS web_return_cnt
    FROM reason r
    LEFT JOIN store_agg s ON s.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_agg w ON w.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND r.r_reason_desc LIKE '%color%'
      AND r.r_reason_id = 'AAAAAAAADBAAAAAA'
      AND (COALESCE(s.total_store_return_amt, 0) > 0 OR COALESCE(w.total_web_return_amt, 0) > 0)
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_reason_sk = r.r_reason_sk
            AND sr.sr_return_tax > 10
      )
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_fee < 20
      )
),
combined AS (
    SELECT
        r_reason_desc,
        total_store_return_amt,
        total_web_return_amt,
        (total_store_return_amt + total_web_return_amt) AS total_combined_return_amt,
        (store_return_cnt + web_return_cnt) AS total_return_cnt,
        CASE
            WHEN (store_return_cnt + web_return_cnt) > 0
            THEN (total_store_return_amt + total_web_return_amt) / (store_return_cnt + web_return_cnt)
            ELSE 0
        END AS avg_return_amt_per_return
    FROM reason_agg
)
SELECT
    r_reason_desc,
    total_combined_return_amt,
    total_return_cnt,
    avg_return_amt_per_return
FROM combined
WHERE total_combined_return_amt > (
    SELECT AVG(total_combined_return_amt) FROM combined
)
ORDER BY total_combined_return_amt DESC
LIMIT 100
