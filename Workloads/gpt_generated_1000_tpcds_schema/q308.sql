WITH base1 AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        ws.web_name,
        st.s_store_name,
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND st.s_state = 'CA'
      AND ib.ib_upper_bound >= 150000
      AND r.r_reason_desc LIKE '%defect%'
      AND sr.sr_return_amt > 500
      AND cd.cd_gender = 'M'
      AND NOT EXISTS (
          SELECT 1 FROM reason r2
          WHERE r2.r_reason_sk = sr.sr_reason_sk
            AND r2.r_reason_desc = 'Other'
      )
),
base2 AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        ws.web_name,
        st.s_store_name,
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND st.s_state = 'NY'
      AND ib.ib_upper_bound <= 120000
      AND r.r_reason_desc LIKE '%damaged%'
      AND sr.sr_return_amt BETWEEN 100 AND 300
      AND cd.cd_gender = 'F'
      AND NOT EXISTS (
          SELECT 1 FROM reason r2
          WHERE r2.r_reason_sk = sr.sr_reason_sk
            AND r2.r_reason_desc = 'Other'
      )
)
SELECT
    u.d_year,
    u.s_store_name,
    u.cd_gender,
    u.web_name,
    COUNT(DISTINCT u.c_customer_id) AS unique_customers,
    SUM(u.sr_return_amt) AS total_return_amount,
    AVG(u.sr_net_loss) AS avg_net_loss,
    MIN(u.sr_return_amt) AS min_return_amt,
    MAX(u.sr_return_amt) AS max_return_amt
FROM (
    SELECT * FROM base1
    UNION
    SELECT * FROM base2
) u
GROUP BY u.d_year, u.s_store_name, u.cd_gender, u.web_name
ORDER BY total_return_amount DESC
LIMIT 100
