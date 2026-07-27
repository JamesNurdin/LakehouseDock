WITH filtered_sales AS (
    SELECT
        cs.cs_net_profit,
        d.d_year,
        c.c_email_address,
        ca.ca_state,
        i.i_category,
        i.i_item_desc,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'High'
            ELSE 'Low'
        END AS profit_level,
        SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_user
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_email_address, '\\.com$')
      AND regexp_like(i.i_item_desc, '(?i)premium|deluxe')
      AND i.i_item_desc LIKE '%Size%'
)
SELECT
    ca_state,
    i_category,
    profit_level,
    COUNT(*) AS orders,
    SUM(cs_net_profit) AS total_profit,
    MAX(email_user) AS sample_user
FROM filtered_sales
GROUP BY ca_state, i_category, profit_level
ORDER BY total_profit DESC
LIMIT 100
