WITH joined_data AS (
    SELECT
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        sr.sr_store_sk,
        s.s_store_name,
        s.s_gmt_offset,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        hd_cur.hd_vehicle_count
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk                     -- rule 2
    JOIN household_demographics hd_cur
        ON c.c_current_hdemo_sk = hd_cur.hd_demo_sk           -- rule 5
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk        -- rule 6
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk                      -- rule 3
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk                    -- rule 4
    WHERE s.s_gmt_offset = -5.00                                 -- predicate 1
      AND r.r_reason_desc LIKE '%color%'                        -- predicate 2
      AND c.c_preferred_cust_flag = 'Y'                         -- predicate 3
      AND ib.ib_lower_bound >= 30000                           -- predicate 4
      AND sr.sr_return_amt > 100.00                             -- predicate 5
),
ranked_data AS (
    SELECT
        jd.*, 
        ROW_NUMBER() OVER (PARTITION BY jd.sr_store_sk ORDER BY jd.sr_returned_date_sk DESC) AS rn_store_return_date,
        SUM(jd.sr_return_amt) OVER (
            PARTITION BY jd.sr_store_sk 
            ORDER BY jd.sr_returned_date_sk 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_store_return_amt,
        LAG(jd.sr_return_amt, 1) OVER (PARTITION BY jd.sr_store_sk ORDER BY jd.sr_returned_date_sk) AS prev_return_amt,
        RANK() OVER (PARTITION BY jd.sr_store_sk ORDER BY jd.sr_return_amt DESC) AS return_amt_rank
    FROM joined_data jd
),
filtered_ranked AS (
    SELECT *
    FROM ranked_data
    WHERE rn_store_return_date <= 5
)
SELECT
    fr.sr_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.s_store_name,
    fr.sr_returned_date_sk,
    fr.sr_return_amt,
    fr.prev_return_amt,
    fr.running_store_return_amt,
    fr.return_amt_rank
FROM filtered_ranked fr
EXCEPT
SELECT
    fr2.sr_customer_sk,
    fr2.c_first_name,
    fr2.c_last_name,
    fr2.s_store_name,
    fr2.sr_returned_date_sk,
    fr2.sr_return_amt,
    fr2.prev_return_amt,
    fr2.running_store_return_amt,
    fr2.return_amt_rank
FROM filtered_ranked fr2
WHERE fr2.return_amt_rank > 3
ORDER BY sr_returned_date_sk DESC
LIMIT 100
