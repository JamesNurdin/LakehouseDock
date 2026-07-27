WITH sales AS (
    SELECT
        ca.ca_state,
        'sales' AS record_type,
        SUM(cs.cs_net_profit) AS amount,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid_inc_ship > 500
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = cs.cs_bill_customer_sk
            AND sr.sr_return_amt > 200
      )
    GROUP BY ca.ca_state
),
returns AS (
    SELECT
        ca.ca_state,
        'returns' AS record_type,
        SUM(sr.sr_net_loss) AS amount,
        COUNT(*) AS txn_cnt
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 100
      AND ca.ca_street_type = 'Ave'
    GROUP BY ca.ca_state
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY amount DESC
LIMIT 100
