WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_ret.d_year,
        d_ret.d_date,
        sr.sr_returned_date_sk,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        r.r_reason_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        ca.ca_state,
        ca.ca_zip,
        ws.web_name
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d_store_close ON s.s_closed_date_sk = d_store_close.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_store_close.d_date_sk
    WHERE d_ret.d_year = 1999
      AND s.s_state = 'CA'
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_upper_bound >= 50000
      AND r.r_reason_desc NOT LIKE '%Lost%'
      AND cd.cd_gender = 'M'
)
SELECT
    b.s_store_name,
    b.d_year,
    b.cd_gender,
    b.hd_buy_potential,
    b.ib_lower_bound,
    b.ib_upper_bound,
    b.r_reason_desc,
    b.sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_sk ORDER BY b.sr_return_amt DESC) AS rn_return_amt,
    SUM(b.sr_return_amt) OVER (PARTITION BY b.s_store_sk) AS total_return_amt_by_store,
    (
        SELECT COUNT(DISTINCT ca2.ca_zip)
        FROM customer_address ca2
        WHERE ca2.ca_state = b.ca_state
    ) AS distinct_zip_per_state,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = b.s_store_sk
          AND sr2.sr_returned_date_sk = b.sr_returned_date_sk
    ) AS total_return_amt_for_store_date
FROM base b
WHERE NOT EXISTS (
    SELECT 1 FROM web_site ws2
    WHERE ws2.web_site_id = b.s_store_id
)
ORDER BY b.sr_return_amt DESC, rn_return_amt
LIMIT 100
