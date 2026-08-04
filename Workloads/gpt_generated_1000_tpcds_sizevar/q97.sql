WITH base AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_ship_cost,
        d.d_year,
        s.s_store_name
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'TX'
      AND s.s_city = 'Lakeside'
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound >= 80000
      AND r.r_reason_desc LIKE '%defect%'
      AND s.s_county = 'Mobile County'
)
SELECT
    store_word,
    d_year,
    COUNT(DISTINCT sr_ticket_number) AS cnt_tickets,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_quantity) AS avg_return_qty,
    MIN(sr_return_ship_cost) AS min_ship_cost,
    MAX(sr_return_tax) AS max_return_tax
FROM base
CROSS JOIN UNNEST(split(base.s_store_name, ' ')) AS t(store_word)
GROUP BY store_word, d_year
ORDER BY total_return_amt DESC
LIMIT 20
