WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    SUM(ss.ss_net_paid) AS store_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cc.cc_tax_percentage) AS total_tax_pct
FROM sampled_store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
FULL OUTER JOIN catalog_returns cr
  ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
  AND ws.ws_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND c.c_preferred_cust_flag = 'Y'
    AND cc.cc_company = 3
    AND ss.ss_quantity > 1
    AND ws.ws_quantity > 0
GROUP BY
    d.d_year,
    c.c_customer_id
ORDER BY
    store_net_paid DESC,
    web_net_paid DESC
OFFSET 0 LIMIT 100
