WITH filtered_sales AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(c.c_email_address, '@.*\\.com$')
      AND regexp_like(i.i_item_desc, 'BRIGHT')
)
SELECT
    ca_state,
    email_domain,
    COUNT(DISTINCT c_customer_sk) AS num_customers,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit
FROM filtered_sales
GROUP BY ca_state, email_domain
ORDER BY total_profit DESC
LIMIT 100
