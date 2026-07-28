/*
Goal: Identify the market classes of call centers that were open on the same day customers (with a corporate "@example.com" email) returned items in 2001, and compute aggregated loss metrics. The query demonstrates string processing (REGEXP_LIKE, REGEXP_EXTRACT, LIKE, CONCAT) together with joins, a CTE, grouping, and a scalar subquery in the HAVING clause.
*/
WITH returns_filtered AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        d.d_year,
        d.d_date_sk AS sr_returned_date_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(c.c_email_address, '@example\\.com$')
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    cc.cc_mkt_class,
    COUNT(DISTINCT rf.sr_customer_sk) AS num_customers,
    SUM(rf.sr_net_loss) AS total_net_loss,
    AVG(rf.sr_return_amt_inc_tax) AS avg_return_amount,
    CONCAT('Market ', cc.cc_mkt_class) AS market_label,
    REGEXP_EXTRACT(cc.cc_mkt_desc, '(\\w+),') AS first_word_desc
FROM returns_filtered rf
JOIN call_center cc ON cc.cc_open_date_sk = rf.sr_returned_date_sk
WHERE REGEXP_LIKE(cc.cc_mkt_class, 'Civil|National')
  AND cc.cc_suite_number LIKE 'Suite %'
GROUP BY cc.cc_mkt_class, cc.cc_mkt_desc
HAVING SUM(rf.sr_net_loss) > (
    SELECT AVG(sr2.sr_net_loss)
    FROM store_returns sr2
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
ORDER BY total_net_loss DESC
LIMIT 10
