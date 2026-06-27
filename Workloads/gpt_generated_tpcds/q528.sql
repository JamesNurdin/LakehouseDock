WITH store AS (
    SELECT
        date_dim.d_date AS month_date,
        item.i_category AS category,
        reason.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        CAST(NULL AS varchar) AS web_page_type,
        store_returns.sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns
    JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN item ON store_returns.sr_item_sk = item.i_item_sk
    JOIN reason ON store_returns.sr_reason_sk = reason.r_reason_sk
    JOIN customer_demographics cd ON store_returns.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON store_returns.sr_hdemo_sk = hd.hd_demo_sk
),
catalog AS (
    SELECT
        date_dim.d_date AS month_date,
        item.i_category AS category,
        reason.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        CAST(NULL AS varchar) AS web_page_type,
        catalog_returns.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns
    JOIN date_dim ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
    JOIN reason ON catalog_returns.cr_reason_sk = reason.r_reason_sk
    JOIN customer_demographics cd ON catalog_returns.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON catalog_returns.cr_refunded_hdemo_sk = hd.hd_demo_sk
),
web AS (
    SELECT
        date_dim.d_date AS month_date,
        item.i_category AS category,
        reason.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        wp.wp_type AS web_page_type,
        web_returns.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns
    JOIN date_dim ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
    JOIN item ON web_returns.wr_item_sk = item.i_item_sk
    JOIN reason ON web_returns.wr_reason_sk = reason.r_reason_sk
    JOIN customer_demographics cd ON web_returns.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON web_returns.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON web_returns.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    date_trunc('month', month_date) AS month,
    category,
    reason_desc,
    gender,
    buy_potential,
    web_page_type,
    channel,
    sum(net_loss) AS total_net_loss,
    count(*) AS return_cnt
FROM (
    SELECT * FROM store
    UNION ALL
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
) u
WHERE month_date >= DATE '2001-01-01' AND month_date < DATE '2002-01-01'
GROUP BY
    date_trunc('month', month_date),
    category,
    reason_desc,
    gender,
    buy_potential,
    web_page_type,
    channel
ORDER BY
    month,
    total_net_loss DESC
