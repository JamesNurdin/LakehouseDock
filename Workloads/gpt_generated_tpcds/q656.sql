WITH
    store_returns_cte AS (
        SELECT
            'store' AS channel,
            i.i_category AS item_category,
            r.r_reason_desc AS reason_desc,
            hd.hd_income_band_sk AS income_band,
            s.s_store_name AS store_name,
            sr.sr_net_loss AS net_loss
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
    ),
    catalog_returns_cte AS (
        SELECT
            'catalog' AS channel,
            i.i_category AS item_category,
            r.r_reason_desc AS reason_desc,
            hd.hd_income_band_sk AS income_band,
            CAST(NULL AS varchar) AS store_name,
            cr.cr_net_loss AS net_loss
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    ),
    web_returns_cte AS (
        SELECT
            'web' AS channel,
            i.i_category AS item_category,
            r.r_reason_desc AS reason_desc,
            hd.hd_income_band_sk AS income_band,
            CAST(NULL AS varchar) AS store_name,
            wr.wr_net_loss AS net_loss
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    )
SELECT
    channel,
    item_category,
    reason_desc,
    income_band,
    COUNT(*) AS return_count,
    SUM(net_loss) AS total_net_loss
FROM (
    SELECT * FROM store_returns_cte
    UNION ALL
    SELECT * FROM catalog_returns_cte
    UNION ALL
    SELECT * FROM web_returns_cte
) AS all_returns
GROUP BY
    channel,
    item_category,
    reason_desc,
    income_band
HAVING SUM(net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
