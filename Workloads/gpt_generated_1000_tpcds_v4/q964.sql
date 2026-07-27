WITH store_ret AS (
    SELECT
        sr.sr_store_sk AS sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk AS sr_customer_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        c.c_birth_year,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d.d_year,
        d.d_quarter_seq,
        t.t_hour
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state = 'CA'
      AND c.c_birth_year BETWEEN 1960 AND 1975
      AND ib.ib_lower_bound > 50000
      AND d.d_year = 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
),
web_ret AS (
    SELECT
        CAST(NULL AS integer) AS sr_store_sk,
        wr.wr_returned_date_sk AS sr_returned_date_sk,
        wr.wr_returned_time_sk AS sr_return_time_sk,
        wr.wr_returning_customer_sk AS sr_customer_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        c.c_birth_year,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d.d_year,
        d.d_quarter_seq,
        t.t_hour
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_state = 'CA'
      AND c.c_birth_year BETWEEN 1960 AND 1975
      AND ib.ib_lower_bound > 50000
      AND d.d_year = 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
),
combined AS (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
),
agg_by_store_quarter AS (
    SELECT
        COALESCE(sr_store_sk, -1) AS store_sk,
        d_quarter_seq,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM combined
    GROUP BY COALESCE(sr_store_sk, -1), d_quarter_seq
),
final AS (
    SELECT
        store_sk,
        d_quarter_seq,
        total_return_amt_inc_tax,
        total_net_loss,
        cnt_returns,
        total_net_loss / NULLIF(cnt_returns, 0) AS avg_net_loss_per_return
    FROM agg_by_store_quarter
    WHERE total_net_loss > (
        SELECT AVG(total_net_loss) FROM agg_by_store_quarter
    )
)
SELECT
    f.store_sk,
    f.d_quarter_seq,
    f.total_return_amt_inc_tax,
    f.total_net_loss,
    f.cnt_returns,
    f.avg_net_loss_per_return
FROM final f
ORDER BY f.total_net_loss DESC
LIMIT 100
