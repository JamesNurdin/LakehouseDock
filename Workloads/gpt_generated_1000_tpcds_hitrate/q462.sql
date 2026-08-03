WITH dim_income AS (
    SELECT hd.hd_demo_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 50000
),
joined_facts AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_market_id,
        td.t_hour,
        r.r_reason_desc,
        sr.sr_ticket_number,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        sr.sr_return_amt AS sr_return_amt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN dim_income di ON sr.sr_hdemo_sk = di.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_hdemo_sk = di.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_hdemo_sk = di.hd_demo_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_hour BETWEEN 12 AND 18
      AND s.s_state = 'CA'
      AND di.ib_lower_bound <= 80000
      AND r.r_reason_desc LIKE '%damage%'
      AND EXISTS (
          SELECT 1 FROM store s2
          WHERE s2.s_store_sk = s.s_store_sk
            AND s2.s_market_id = 1
      )
),
agg_facts AS (
    SELECT
        s_store_id,
        t_hour,
        r_reason_desc,
        COUNT(DISTINCT sr_ticket_number) AS store_return_cnt,
        SUM(sr_net_loss) AS total_store_net_loss,
        SUM(cr_net_loss) AS total_catalog_net_loss,
        SUM(wr_net_loss) AS total_web_net_loss,
        AVG(sr_return_amt) AS avg_store_return_amt
    FROM joined_facts
    GROUP BY s_store_id, t_hour, r_reason_desc
    HAVING SUM(sr_net_loss) > 1000
)
SELECT
    s_store_id,
    t_hour,
    r_reason_desc,
    store_return_cnt,
    total_store_net_loss,
    total_catalog_net_loss,
    total_web_net_loss,
    avg_store_return_amt,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_store_net_loss DESC) AS loss_rank
FROM agg_facts
ORDER BY total_store_net_loss DESC
LIMIT 100
