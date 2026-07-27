WITH returns_agg AS (
    SELECT
        sr_customer_sk,
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_refunded_cash) AS total_refunded_cash
    FROM store_returns
    WHERE sr_return_amt > 0
      AND sr_refunded_cash > 0
    GROUP BY sr_customer_sk, sr_returned_date_sk
)
SELECT
    c.c_customer_id,
    d_sold.d_year,
    ws.web_name,
    cc.cc_name,
    cp.cp_department,
    cs.cs_net_profit,
    ra.total_return_amt,
    (cs.cs_net_profit - COALESCE(ra.total_return_amt, 0)) AS net_profit_adj,
    CASE
        WHEN (cs.cs_net_profit - COALESCE(ra.total_return_amt, 0)) > 1000 THEN 'High'
        WHEN (cs.cs_net_profit - COALESCE(ra.total_return_amt, 0)) BETWEEN 0 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY (cs.cs_net_profit - COALESCE(ra.total_return_amt, 0)) DESC) AS profit_rank
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN returns_agg ra
    ON ra.sr_customer_sk = c.c_customer_sk
   AND ra.sr_returned_date_sk = d_sold.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND cc.cc_division_name = 'able'
  AND cp.cp_department = 'Books'
  AND ws.web_state = 'CA'
  AND wp.wp_char_count > 500
  AND cs.cs_quantity > 1
ORDER BY profit_rank
LIMIT 100
