WITH
    store_agg AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_cdemo_sk,
            sr.sr_reason_sk,
            SUM(sr.sr_net_loss) AS store_net_loss,
            SUM(sr.sr_return_quantity) AS store_qty
        FROM tpcds.store_returns sr
        GROUP BY sr.sr_returned_date_sk, sr.sr_cdemo_sk, sr.sr_reason_sk
    ),
    web_agg AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_refunded_cdemo_sk,
            wr.wr_reason_sk,
            SUM(wr.wr_net_loss) AS web_net_loss,
            SUM(wr.wr_return_quantity) AS web_qty
        FROM tpcds.web_returns wr
        GROUP BY wr.wr_returned_date_sk, wr.wr_refunded_cdemo_sk, wr.wr_reason_sk
    ),
    store_enriched AS (
        SELECT
            d1.d_year,
            cd1.cd_gender,
            r1.r_reason_desc,
            s.store_net_loss,
            s.store_qty
        FROM store_agg s
        JOIN tpcds.date_dim d1 ON s.sr_returned_date_sk = d1.d_date_sk                        -- join 1
        JOIN tpcds.customer_demographics cd1 ON s.sr_cdemo_sk = cd1.cd_demo_sk                -- join 2
        JOIN tpcds.reason r1 ON s.sr_reason_sk = r1.r_reason_sk                                 -- join 3
        JOIN tpcds.date_dim d1_extra ON s.sr_returned_date_sk = d1_extra.d_date_sk            -- join 4
        JOIN tpcds.reason r1_extra ON s.sr_reason_sk = r1_extra.r_reason_sk                    -- join 5
    ),
    web_enriched AS (
        SELECT
            d2.d_year,
            cd2.cd_gender,
            r2.r_reason_desc,
            w.web_net_loss,
            w.web_qty
        FROM web_agg w
        JOIN tpcds.date_dim d2 ON w.wr_returned_date_sk = d2.d_date_sk                        -- join 6
        JOIN tpcds.customer_demographics cd2 ON w.wr_refunded_cdemo_sk = cd2.cd_demo_sk      -- join 7
        JOIN tpcds.reason r2 ON w.wr_reason_sk = r2.r_reason_sk                                 -- join 8
        JOIN tpcds.reason r2_extra ON w.wr_reason_sk = r2_extra.r_reason_sk                    -- join 9
    )
SELECT
    COALESCE(se.d_year, we.d_year) AS year,
    COALESCE(se.cd_gender, we.cd_gender) AS gender,
    COALESCE(se.r_reason_desc, we.r_reason_desc) AS reason,
    SUM(se.store_net_loss) AS total_store_net_loss,
    SUM(se.store_qty) AS total_store_qty,
    SUM(we.web_net_loss) AS total_web_net_loss,
    SUM(we.web_qty) AS total_web_qty
FROM store_enriched se
FULL OUTER JOIN web_enriched we
    ON se.d_year = we.d_year
   AND se.cd_gender = we.cd_gender
   AND se.r_reason_desc = we.r_reason_desc
WHERE COALESCE(se.d_year, we.d_year) BETWEEN 2000 AND 2002
GROUP BY
    COALESCE(se.d_year, we.d_year),
    COALESCE(se.cd_gender, we.cd_gender),
    COALESCE(se.r_reason_desc, we.r_reason_desc)
ORDER BY year, gender, total_store_net_loss DESC
