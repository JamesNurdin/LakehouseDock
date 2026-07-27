WITH returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_hdemo_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN sr.sr_return_tax > 0 THEN 1 ELSE 0 END) AS cnt_taxed_returns
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
    GROUP BY sr.sr_store_sk, sr.sr_hdemo_sk, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_store_closed.d_year AS store_closed_year,
    cp.cp_department,
    wp.wp_type,
    ra.total_return_amt,
    ra.total_net_loss,
    ra.cnt_returns,
    CASE WHEN ra.total_return_amt = 0 THEN 0
         ELSE ra.total_net_loss / ra.total_return_amt
    END AS loss_ratio,
    (SELECT AVG(sr_inner.sr_return_amt) FROM store_returns sr_inner) AS overall_avg_return_amt
FROM returns_agg ra
JOIN store s
    ON ra.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN household_demographics hd
    ON ra.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store_closed.d_date_sk
WHERE s.s_state = 'CA'
  AND wp.wp_type = 'ad'
  AND hd.hd_vehicle_count >= 2
ORDER BY loss_ratio DESC, s.s_store_id
