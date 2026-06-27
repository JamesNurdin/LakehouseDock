WITH all_returns AS (
    -- Catalog returns
    SELECT
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        reason.r_reason_desc AS reason_desc,
        customer_demographics.cd_gender AS gender,
        catalog_returns.cr_net_loss AS net_loss
    FROM catalog_returns
    JOIN date_dim ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN reason ON catalog_returns.cr_reason_sk = reason.r_reason_sk
    JOIN customer_demographics ON catalog_returns.cr_refunded_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE date_dim.d_year = 2000

    UNION ALL

    -- Store returns
    SELECT
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        reason.r_reason_desc AS reason_desc,
        customer_demographics.cd_gender AS gender,
        store_returns.sr_net_loss AS net_loss
    FROM store_returns
    JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN reason ON store_returns.sr_reason_sk = reason.r_reason_sk
    JOIN customer_demographics ON store_returns.sr_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE date_dim.d_year = 2000

    UNION ALL

    -- Web returns
    SELECT
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        reason.r_reason_desc AS reason_desc,
        customer_demographics.cd_gender AS gender,
        web_returns.wr_net_loss AS net_loss
    FROM web_returns
    JOIN date_dim ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
    JOIN reason ON web_returns.wr_reason_sk = reason.r_reason_sk
    JOIN customer_demographics ON web_returns.wr_refunded_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN web_page ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
    WHERE date_dim.d_year = 2000
),
aggregated AS (
    SELECT
        year,
        month_seq,
        reason_desc,
        gender,
        sum(net_loss) AS total_net_loss
    FROM all_returns
    GROUP BY year, month_seq, reason_desc, gender
)
SELECT
    year,
    month_seq,
    reason_desc,
    gender,
    total_net_loss,
    row_number() OVER (PARTITION BY year, month_seq ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY year, month_seq, loss_rank
