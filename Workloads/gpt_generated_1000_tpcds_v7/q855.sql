WITH store_ret AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        i.i_category,
        d.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cp.cp_type,
        p.p_promo_name
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN catalog_page cp
        ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i2.i_category,
        d2.d_year,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        hd_ret.hd_income_band_sk AS returning_income_band,
        p2.p_promo_name AS promo_name
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN promotion p2
        ON p2.p_item_sk = i2.i_item_sk
        AND d2.d_date_sk BETWEEN p2.p_start_date_sk AND p2.p_end_date_sk
)
SELECT
    COALESCE(sr.i_category, wr.i_category) AS category,
    COALESCE(sr.d_year, wr.d_year) AS year,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amt,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amt,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT COALESCE(sr.sr_item_sk, wr.wr_item_sk)) AS distinct_items_returned,
    RANK() OVER (PARTITION BY COALESCE(sr.d_year, wr.d_year) ORDER BY SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) DESC) AS loss_rank
FROM store_ret sr
FULL OUTER JOIN web_ret wr
    ON sr.sr_item_sk = wr.wr_item_sk
   AND sr.sr_returned_date_sk = wr.wr_returned_date_sk
GROUP BY
    COALESCE(sr.i_category, wr.i_category),
    COALESCE(sr.d_year, wr.d_year)
ORDER BY total_net_loss DESC
LIMIT 100
