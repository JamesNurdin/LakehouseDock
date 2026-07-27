/*
  Goal: Identify the top customer demographic groups (by gender and credit rating) for web returns in 2002, 
  showing total return amount and count, classifying credit rating into High/Low, and linking any promotional 
  information that started on the earliest return date for each group. The result ranks groups overall and within 
  each credit category, handling missing promotions via a LEFT OUTER JOIN and COALESCE.
*/
WITH demo_year_returns AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        d.d_year,
        MIN(d.d_date_sk) AS first_date_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS return_cnt,
        CASE
            WHEN cd.cd_credit_rating IN ('A', 'B') THEN 'High'
            ELSE 'Low'
        END AS credit_category
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE wr.wr_return_amt_inc_tax > 100                     -- predicate 1
      AND cd.cd_gender = 'M'                                 -- predicate 2
      AND d.d_year = 2002                                    -- predicate 3
      AND d.d_quarter_seq > 5                               -- predicate 4
      AND wr.wr_account_credit >= 200                        -- predicate 5
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_credit_rating, d.d_year
)
SELECT
    dy.d_year,
    COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
    dy.cd_gender,
    dy.credit_category,
    dy.total_return_amt,
    dy.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY dy.credit_category ORDER BY dy.total_return_amt DESC) AS rn_in_category,
    RANK()        OVER (ORDER BY dy.total_return_amt DESC)                     AS overall_rank
FROM demo_year_returns dy
LEFT JOIN promotion p
    ON p.p_start_date_sk = dy.first_date_sk                -- follows join rule
   AND p.p_channel_tv = 'N'                                 -- predicate 6 (kept in ON to preserve outer join)
   AND p.p_end_date_sk IN (2450357, 2450365, 2450640)      -- predicate 7
ORDER BY dy.total_return_amt DESC
LIMIT 100
