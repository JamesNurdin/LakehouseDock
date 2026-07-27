WITH return_union AS (
    SELECT sr.sr_addr_sk AS addr_sk,
           SUM(sr.sr_return_amt) AS total_return,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_return_amt > 50
    GROUP BY sr.sr_addr_sk
    UNION ALL
    SELECT wr.wr_refunded_addr_sk AS addr_sk,
           SUM(wr.wr_return_amt) AS total_return,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    WHERE wr.wr_return_amt > 50
    GROUP BY wr.wr_refunded_addr_sk
)
SELECT
    cc.cc_call_center_id,
    ca.ca_city,
    ca.ca_state,
    SUM(cs.cs_ext_sales_price) AS sum_sales,
    SUM(COALESCE(r.total_return, 0)) AS sum_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_net_paid_inc_ship) AS avg_net_paid_inc_ship
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN return_union r
  ON r.addr_sk = ca.ca_address_sk
WHERE cc.cc_division = 5
  AND cc.cc_zip = '70411'
  AND cs.cs_net_paid_inc_ship > 1000
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_addr_sk = ca.ca_address_sk
          AND sr.sr_return_amt > 200
      )
GROUP BY cc.cc_call_center_id, ca.ca_city, ca.ca_state
ORDER BY sum_sales DESC
LIMIT 100
