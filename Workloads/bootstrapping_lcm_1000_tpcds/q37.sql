WITH aggregated_returns AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        cd.cd_gender,
        cd.cd_education_status,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(p_start.p_cost) AS avg_promo_cost_start,
        AVG(p_end.p_cost) AS avg_promo_cost_end,
        MAX(CASE WHEN p_start.p_channel_email = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS max_email_promo_return,
        MIN(CASE WHEN p_end.p_channel_tv = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS min_tv_promo_return,
        ROUND(100.0 * SUM(sr.sr_return_amt) / NULLIF(SUM(sr.sr_return_quantity), 0), 2) AS avg_return_amount_per_item
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN promotion p_start
        ON p_start.p_start_date_sk = d_ret.d_date_sk
    JOIN promotion p_end
        ON p_end.p_end_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
      AND cd.cd_credit_rating IN ('A', 'B')
    GROUP BY
        s.s_store_id,
        s.s_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        cd.cd_gender,
        cd.cd_education_status
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    ar.s_store_id,
    ar.s_state,
    ar.d_year,
    ar.d_month_seq,
    ar.cd_gender,
    ar.cd_education_status,
    ar.num_returns,
    ar.total_return_amount,
    ar.total_net_loss,
    ar.avg_promo_cost_start,
    ar.avg_promo_cost_end,
    ar.max_email_promo_return,
    ar.min_tv_promo_return,
    ar.avg_return_amount_per_item,
    ROW_NUMBER() OVER (PARTITION BY ar.s_state ORDER BY ar.total_return_amount DESC) AS rank_by_state
FROM aggregated_returns ar
ORDER BY ar.total_return_amount DESC
LIMIT 100
