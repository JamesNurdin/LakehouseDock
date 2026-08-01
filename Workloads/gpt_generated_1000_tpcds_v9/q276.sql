/*
Goal: Compute the combined net loss from store, catalog, and web returns by year, month, reason description, call‑center division, and web‑page type. The query aggregates each fact table in a CTE, joins all nine selected tables using only the allowed keys, categorises loss levels with a CASE expression, filters on several dimensions, produces subtotals with CUBE, applies a HAVING filter, and returns the top rows with pagination.
*/
WITH
    store_agg AS (
        SELECT
            sr_returned_date_sk,
            sr_return_time_sk,
            sr_hdemo_sk,
            sr_reason_sk,
            SUM(sr_net_loss) AS store_net_loss,
            COUNT(*) AS store_return_cnt
        FROM store_returns
        GROUP BY sr_returned_date_sk, sr_return_time_sk, sr_hdemo_sk, sr_reason_sk
    ),
    catalog_agg AS (
        SELECT
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_refunded_hdemo_sk,
            cr_reason_sk,
            cr_call_center_sk,
            SUM(cr_net_loss) AS catalog_net_loss,
            COUNT(*) AS catalog_return_cnt
        FROM catalog_returns
        GROUP BY cr_returned_date_sk, cr_returned_time_sk, cr_refunded_hdemo_sk, cr_reason_sk, cr_call_center_sk
    ),
    web_agg AS (
        SELECT
            wr_returned_date_sk,
            wr_returned_time_sk,
            wr_refunded_hdemo_sk,
            wr_reason_sk,
            wr_web_page_sk,
            SUM(wr_net_loss) AS web_net_loss,
            COUNT(*) AS web_return_cnt
        FROM web_returns
        GROUP BY wr_returned_date_sk, wr_returned_time_sk, wr_refunded_hdemo_sk, wr_reason_sk, wr_web_page_sk
    )
SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    cc.cc_division_name,
    wp.wp_type,
    SUM(sa.store_net_loss)                AS total_store_loss,
    SUM(ca.catalog_net_loss)              AS total_catalog_loss,
    SUM(wa.web_net_loss)                  AS total_web_loss,
    SUM(sa.store_net_loss + ca.catalog_net_loss + wa.web_net_loss) AS total_combined_loss,
    CASE
        WHEN SUM(sa.store_net_loss + ca.catalog_net_loss + wa.web_net_loss) > 100000 THEN 'HIGH'
        WHEN SUM(sa.store_net_loss + ca.catalog_net_loss + wa.web_net_loss) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                   AS loss_category,
    (
        SELECT AVG(combined_loss)
        FROM (
            SELECT SUM(
                       COALESCE(sa2.store_net_loss, 0) +
                       COALESCE(ca2.catalog_net_loss, 0) +
                       COALESCE(wa2.web_net_loss, 0)
                   ) AS combined_loss
            FROM store_agg sa2
            LEFT JOIN catalog_agg ca2
                ON sa2.sr_returned_date_sk = ca2.cr_returned_date_sk
               AND sa2.sr_return_time_sk   = ca2.cr_returned_time_sk
               AND sa2.sr_hdemo_sk        = ca2.cr_refunded_hdemo_sk
               AND sa2.sr_reason_sk       = ca2.cr_reason_sk
            LEFT JOIN web_agg wa2
                ON sa2.sr_returned_date_sk = wa2.wr_returned_date_sk
               AND sa2.sr_return_time_sk   = wa2.wr_returned_time_sk
               AND sa2.sr_hdemo_sk        = wa2.wr_refunded_hdemo_sk
               AND sa2.sr_reason_sk       = wa2.wr_reason_sk
            GROUP BY sa2.sr_reason_sk
        ) t
    )                                     AS avg_combined_loss_per_reason
FROM
    store_agg sa
    JOIN catalog_agg ca
        ON sa.sr_returned_date_sk = ca.cr_returned_date_sk
       AND sa.sr_return_time_sk   = ca.cr_returned_time_sk
       AND sa.sr_hdemo_sk        = ca.cr_refunded_hdemo_sk
       AND sa.sr_reason_sk       = ca.cr_reason_sk
    JOIN web_agg wa
        ON sa.sr_returned_date_sk = wa.wr_returned_date_sk
       AND sa.sr_return_time_sk   = wa.wr_returned_time_sk
       AND sa.sr_hdemo_sk        = wa.wr_refunded_hdemo_sk
       AND sa.sr_reason_sk       = wa.wr_reason_sk
    JOIN date_dim d
        ON sa.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sa.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON sa.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sa.sr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON ca.cr_call_center_sk = cc.cc_call_center_sk
       AND cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wa.wr_web_page_sk = wp.wp_web_page_sk
       AND wp.wp_creation_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND r.r_reason_id LIKE 'AAAA%'
    AND cc.cc_division_name = 'able'
    AND hd.hd_vehicle_count >= 0
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    CUBE (d.d_year, d.d_month_seq, r.r_reason_desc, cc.cc_division_name, wp.wp_type)
HAVING
    SUM(sa.store_net_loss + ca.catalog_net_loss + wa.web_net_loss) > 0
ORDER BY
    d.d_year DESC,
    d.d_month_seq,
    total_combined_loss DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
