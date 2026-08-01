WITH catalog_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
key_diff AS (
    SELECT ca_state
    FROM customer_address
    EXCEPT
    SELECT ca_state
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),
joined_data AS (
    SELECT
        ca.ca_state,
        ca.ca_address_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        (SELECT COALESCE(SUM(sr2.sr_return_amt_inc_tax), 0)
         FROM store_returns sr2
         WHERE sr2.sr_addr_sk = ca.ca_address_sk) AS address_return_total,
        CASE
            WHEN SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) = 0 THEN 'No Sales'
            WHEN SUM(sr.sr_return_amt_inc_tax) / NULLIF((SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)), 0) > 0.2 THEN 'High Returns'
            ELSE 'Normal'
        END AS return_category
    FROM catalog_sample cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    RIGHT JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    RIGHT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ca.ca_gmt_offset BETWEEN -9.00 AND -6.00
      AND d.d_year = 2001
      AND wp.wp_type = 'article'
      AND r.r_reason_desc IS NOT NULL
    GROUP BY GROUPING SETS (
        (ca.ca_state, ca.ca_address_sk, d.d_year, d.d_month_seq),
        (ca.ca_state, ca.ca_address_sk, d.d_year),
        (ca.ca_state, ca.ca_address_sk),
        ()
    )
)
SELECT
    jd.ca_state,
    jd.d_year,
    jd.d_month_seq,
    jd.catalog_net_paid,
    jd.web_net_paid,
    jd.total_return_inc_tax,
    jd.address_return_total,
    jd.return_category
FROM joined_data jd
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr3
    WHERE sr3.sr_addr_sk = jd.ca_address_sk
)
  AND jd.ca_state IN (SELECT ca_state FROM key_diff)
ORDER BY jd.ca_state ASC NULLS LAST, jd.d_year DESC, jd.d_month_seq
LIMIT 100
