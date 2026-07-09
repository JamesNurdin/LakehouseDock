WITH aggregated_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        cd_ret.cd_gender AS returning_gender,
        cd_ref.cd_gender AS refunded_gender,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_demographics cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE d.d_year BETWEEN 2010 AND 2020
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        cd_ret.cd_gender,
        cd_ref.cd_gender,
        hd_ret.hd_buy_potential,
        hd_ref.hd_buy_potential
    HAVING COUNT(*) > 5
)
SELECT
    ar.s_store_id,
    ar.s_store_name,
    ar.s_state,
    ar.d_year,
    ar.d_month_seq,
    ar.returning_gender,
    ar.refunded_gender,
    ar.returning_buy_potential,
    ar.refunded_buy_potential,
    ar.total_returns,
    ar.total_return_amount,
    ar.total_net_loss,
    ar.avg_return_quantity,
    CASE
        WHEN ar.total_return_amount > 10000 THEN 'Very High'
        WHEN ar.total_return_amount > 5000 THEN 'High'
        WHEN ar.total_return_amount > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category,
    ROW_NUMBER() OVER (PARTITION BY ar.s_store_id ORDER BY ar.total_return_amount DESC) AS store_rank_by_return_amount
FROM aggregated_returns ar
ORDER BY ar.total_return_amount DESC
LIMIT 100
