WITH sales_agg AS (
   SELECT
       ca.ca_state AS state,
       cd.cd_credit_rating AS credit_rating,
       SUM(cs.cs_net_paid) AS amount,
       'Sale' AS transaction_type,
       CASE WHEN SUM(cs.cs_net_paid) >= 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND cd.cd_credit_rating IN ('Good', 'High Risk')
   GROUP BY ca.ca_state, cd.cd_credit_rating
)
SELECT
    state,
    credit_rating,
    amount,
    transaction_type,
    profit_flag
FROM sales_agg
UNION ALL
SELECT
    ca.ca_state AS state,
    cd.cd_credit_rating AS credit_rating,
    -SUM(sr.sr_return_amt) AS amount,
    'Return' AS transaction_type,
    CASE WHEN -SUM(sr.sr_return_amt) >= 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND cd.cd_credit_rating IN ('Good', 'High Risk')
GROUP BY ca.ca_state, cd.cd_credit_rating
ORDER BY state, credit_rating, transaction_type
