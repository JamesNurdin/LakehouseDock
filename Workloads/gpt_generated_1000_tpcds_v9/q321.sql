WITH store_agg AS (
    SELECT ca.ca_state AS ca_state,
           'Store' AS sales_channel,
           SUM(ss.ss_net_profit) AS total_net_profit,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_net_profit > 0
    GROUP BY ca.ca_state
),
catalog_agg AS (
    SELECT ca.ca_state AS ca_state,
           'Catalog' AS sales_channel,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_net_profit > 0
    GROUP BY ca.ca_state
)
SELECT DISTINCT ca_state,
                sales_channel,
                total_net_profit,
                distinct_customers
FROM (
    SELECT ca_state,
           sales_channel,
           total_net_profit,
           distinct_customers
    FROM store_agg
    UNION ALL
    SELECT ca_state,
           sales_channel,
           total_net_profit,
           distinct_customers
    FROM catalog_agg
) combined
ORDER BY total_net_profit DESC
LIMIT 100
