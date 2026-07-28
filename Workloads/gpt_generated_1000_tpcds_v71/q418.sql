WITH distinct_web AS (
    SELECT DISTINCT
        wp_customer_sk,
        wp_url,
        wp_link_count,
        wp_creation_date_sk,
        wp_access_date_sk
    FROM web_page
),
store_returns_agg AS (
    SELECT
        sr.sr_customer_sk,
        d_ret.d_year      AS return_year,
        SUM(sr.sr_net_loss)               AS total_net_loss,
        COUNT(*)                         AS return_cnt,
        AVG(sr.sr_return_amt_inc_tax)    AS avg_return_amt_inc_tax
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE sr.sr_return_amt_inc_tax > 200
      AND sr.sr_return_tax BETWEEN 5 AND 15
      AND sr.sr_reversed_charge < 50
    GROUP BY sr.sr_customer_sk, d_ret.d_year
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sra.return_year,
    sra.total_net_loss,
    sra.return_cnt,
    ROUND(sra.avg_return_amt_inc_tax, 2) AS avg_return_amt_inc_tax,
    d_create.d_month_seq               AS page_creation_month,
    dw.wp_link_count,
    RANK() OVER (PARTITION BY sra.return_year ORDER BY sra.total_net_loss DESC) AS net_loss_rank_year,
    CASE
        WHEN dw.wp_link_count > 15 THEN 'HighLinks'
        ELSE 'LowLinks'
    END AS link_category
FROM store_returns_agg sra
JOIN customer c ON c.c_customer_sk = sra.sr_customer_sk
JOIN distinct_web dw ON dw.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_create ON dw.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access ON dw.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_shipto ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND d_shipto.d_year = 2001
  AND d_create.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND d_access.d_day_name = 'Monday'
  AND dw.wp_link_count >= 10
ORDER BY sra.total_net_loss DESC
LIMIT 100
