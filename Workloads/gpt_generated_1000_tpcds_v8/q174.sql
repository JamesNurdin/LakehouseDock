WITH high_catalog AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid_inc_ship > 2000
)
SELECT
    hc.c_customer_id,
    hc.cs_net_paid_inc_ship,
    CASE
        WHEN hc.cs_net_profit > (SELECT avg(cs_net_profit) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM high_catalog hc
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = hc.c_customer_sk
      AND ss.ss_net_paid > 1500
)
EXCEPT
SELECT
    hc.c_customer_id,
    hc.cs_net_paid_inc_ship,
    CASE
        WHEN hc.cs_net_profit > (SELECT avg(cs_net_profit) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM high_catalog hc
JOIN store_sales ss ON ss.ss_customer_sk = hc.c_customer_sk
WHERE ss.ss_net_paid > 1500
ORDER BY c_customer_id
LIMIT 100
