/*
Goal: Combine catalog sales (store_sales) with their corresponding returns (store_returns) to compute a net amount per transaction, apply string pattern filters on item descriptions, derive brand‑class concatenations, identify stores managed by a specific manager, and show the prior net amount using a window function. The result is ordered by net amount and limited to the top 100 rows.
*/
WITH sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        d.d_date,
        d.d_year,
        i.i_item_desc,
        i.i_brand,
        i.i_class,
        CONCAT(i.i_brand, ' ', i.i_class) AS brand_class,
        CASE WHEN regexp_like(i.i_item_desc, '.*[0-9]{3}.*') THEN 'HasDigits' ELSE 'NoDigits' END AS desc_digit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_item_desc LIKE '%o%'
),
returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        d.d_date AS return_date,
        d.d_year AS return_year,
        i.i_item_desc,
        i.i_brand,
        i.i_class,
        CONCAT(i.i_brand, '-', i.i_class) AS brand_class_ret,
        CASE WHEN regexp_like(i.i_item_desc, '^.*[A-Z]{2,}.*$') THEN 1 ELSE 0 END AS upper_flag
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_item_desc LIKE '%e%'
)
SELECT
    COALESCE(s.ss_ticket_number, r.sr_ticket_number) AS ticket_number,
    COALESCE(s.d_date, r.return_date) AS transaction_date,
    COALESCE(s.ss_store_sk, r.sr_store_sk) AS store_sk,
    COALESCE(s.brand_class, r.brand_class_ret) AS brand_class,
    COALESCE(s.ss_net_paid, 0) - COALESCE(r.sr_return_amt, 0) AS net_amount,
    LAG(COALESCE(s.ss_net_paid, 0) - COALESCE(r.sr_return_amt, 0)) OVER (
        PARTITION BY COALESCE(s.ss_store_sk, r.sr_store_sk)
        ORDER BY COALESCE(s.d_date, r.return_date)
    ) AS prev_net_amount,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM store st
            WHERE st.s_store_sk = COALESCE(s.ss_store_sk, r.sr_store_sk)
              AND st.s_market_manager LIKE '%James%'
        ) THEN 'JamesMgr'
        ELSE 'OtherMgr'
    END AS manager_group
FROM sales s
FULL OUTER JOIN returns r
    ON s.ss_ticket_number = r.sr_ticket_number
   AND s.ss_item_sk = r.sr_item_sk
WHERE (s.desc_digit_flag = 'HasDigits' OR r.upper_flag = 1)
  AND (s.brand_class IS NOT NULL OR r.brand_class_ret IS NOT NULL)
ORDER BY net_amount DESC
LIMIT 100
