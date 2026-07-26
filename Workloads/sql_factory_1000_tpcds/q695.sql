WITH catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_bill_addr_sk AS address_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS ext_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk, cs.cs_bill_addr_sk
),
store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_addr_sk AS address_sk,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS ext_sales
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk, ss.ss_addr_sk
),
combined AS (
    SELECT
        customer_sk,
        address_sk,
        SUM(net_profit) AS net_profit,
        SUM(total_quantity) AS total_quantity,
        SUM(ext_sales) AS ext_sales
    FROM (
        SELECT * FROM catalog_agg
        UNION ALL
        SELECT * FROM store_agg
    ) a
    GROUP BY customer_sk, address_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    c.customer_sk,
    c.net_profit,
    c.total_quantity,
    c.ext_sales,
    CASE
        WHEN c.net_profit >= 100000 THEN 'Platinum'
        WHEN c.net_profit >= 50000 THEN 'Gold'
        WHEN c.net_profit >= 20000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    DENSE_RANK() OVER (ORDER BY c.net_profit DESC) AS profit_rank
FROM combined c
JOIN customer_address ca
  ON c.address_sk = ca.ca_address_sk
WHERE c.net_profit > 0
ORDER BY profit_rank
LIMIT 20
