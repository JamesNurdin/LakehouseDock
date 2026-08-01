WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_bill_addr_sk,
        cs.cs_bill_hdemo_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ext_sales_price > 500
      AND cs.cs_quantity >= 2
)
SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    ca.ca_zip,
    ca.ca_state,
    hd.hd_vehicle_count,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cs.cs_net_profit DESC) AS rn_state,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_bill_addr_sk = ca.ca_address_sk
    ) AS avg_net_profit_by_addr,
    CASE WHEN wr.wr_return_amt > 200 THEN 'High' ELSE 'Low' END AS return_category
FROM filtered_sales cs
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.web_returns wr
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   AND wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND hd.hd_vehicle_count >= 1
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_order_number = cs.cs_order_number
          AND wr2.wr_return_amt > 100
    )
ORDER BY cs.cs_net_profit DESC, rn_state
LIMIT 100
