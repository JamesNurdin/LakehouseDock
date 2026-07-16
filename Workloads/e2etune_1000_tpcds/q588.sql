WITH aggregated_returns AS (
    SELECT
        cd_ret.cd_gender AS returning_gender,
        cd_ret.cd_marital_status AS returning_marital_status,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        cd_ref.cd_gender AS refunded_gender,
        cd_ref.cd_marital_status AS refunded_marital_status,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
    FROM web_returns wr
    JOIN customer_demographics cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt > 0
      AND wr.wr_returned_date_sk BETWEEN 2450800 AND 2451100
      AND cd_ret.cd_gender IS NOT NULL
      AND cd_ref.cd_gender IS NOT NULL
    GROUP BY
        cd_ret.cd_gender,
        cd_ret.cd_marital_status,
        hd_ret.hd_buy_potential,
        cd_ref.cd_gender,
        cd_ref.cd_marital_status,
        hd_ref.hd_income_band_sk
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    returning_gender,
    returning_marital_status,
    returning_buy_potential,
    refunded_gender,
    refunded_marital_status,
    refunded_income_band,
    num_returns,
    total_return_amount,
    avg_return_amount,
    total_net_loss,
    distinct_web_pages,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM aggregated_returns
ORDER BY total_return_amount DESC
LIMIT 100
