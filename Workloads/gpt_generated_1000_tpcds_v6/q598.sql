WITH inv_agg AS (
   SELECT inv_date_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_quantity_on_hand
   FROM inventory
   WHERE inv_quantity_on_hand > 0
   GROUP BY inv_date_sk, inv_warehouse_sk
),
cust_total AS (
   SELECT c.c_customer_sk,
          SUM(sr.sr_return_amt) AS total_return_amt
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   GROUP BY c.c_customer_sk
)
SELECT
    d.d_date AS return_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cc.cc_name AS call_center_name,
    cp.cp_catalog_page_id,
    hd.hd_buy_potential,
    ia.total_quantity_on_hand,
    sr.sr_return_amt,
    SUM(sr.sr_return_amt) OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt,
    ct.total_return_amt,
    RANK() OVER (ORDER BY ct.total_return_amt DESC) AS customer_return_rank
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN inv_agg ia ON ia.inv_date_sk = d.d_date_sk
JOIN cust_total ct ON ct.c_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND cc.cc_country = 'United States'
  AND cp.cp_type = 'A'
  AND r.r_reason_desc LIKE 'Did not%'
  AND hd.hd_buy_potential = '501-1000'
  AND ia.total_quantity_on_hand > 100
ORDER BY cumulative_return_amt DESC
LIMIT 100
