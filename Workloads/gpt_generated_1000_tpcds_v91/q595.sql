WITH store_agg AS (
    SELECT
        d_ret.d_date AS return_date,
        ca_ret.ca_state AS state,
        hd_ret.hd_income_band_sk AS income_band,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        'store' AS source
    FROM
        date_dim d_ret
        FULL OUTER JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
        JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
        JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
    WHERE EXISTS (
        SELECT 1 FROM store s2 WHERE s2.s_state = ca_ret.ca_state
    )
    GROUP BY
        d_ret.d_date,
        ca_ret.ca_state,
        hd_ret.hd_income_band_sk
),
web_agg AS (
    SELECT
        d_ret.d_date AS return_date,
        ca_refunded.ca_state AS state,
        hd_refunded.hd_income_band_sk AS income_band,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        'web' AS source
    FROM
        date_dim d_ret
        JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
        JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
        JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
        JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
        JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
        JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
        JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    GROUP BY
        d_ret.d_date,
        ca_refunded.ca_state,
        hd_refunded.hd_income_band_sk
)
SELECT *
FROM (
    SELECT return_date, state, income_band, total_return_amt, return_cnt, source FROM store_agg
    UNION ALL
    SELECT return_date, state, income_band, total_return_amt, return_cnt, source FROM web_agg
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
