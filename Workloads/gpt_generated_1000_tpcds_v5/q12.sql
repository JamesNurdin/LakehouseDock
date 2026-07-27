WITH sales_by_state AS (
    SELECT
        ca.ca_country,
        ca.ca_state,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_ext_tax) > 1000 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND cs.cs_ext_tax > 20
    GROUP BY ca.ca_country, ca.ca_state
),
returns_by_state AS (
    SELECT
        ca.ca_country,
        ca.ca_state,
        -SUM(wr.wr_net_loss) AS total_profit,
        CASE WHEN SUM(wr.wr_return_tax) > 500 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND wr.wr_return_tax > 5
    GROUP BY ca.ca_country, ca.ca_state
)
SELECT * FROM sales_by_state
UNION ALL
SELECT * FROM returns_by_state
ORDER BY total_profit DESC
LIMIT 100
