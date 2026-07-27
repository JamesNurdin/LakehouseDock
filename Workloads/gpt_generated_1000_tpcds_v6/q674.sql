WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_tax,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 2
      AND cs.cs_ext_tax BETWEEN 10 AND 100
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sold.d_date AS sold_date,
    sd.cs_net_paid,
    sd.cs_net_profit,
    CASE
        WHEN sd.cs_net_profit > 1000 THEN 'High'
        WHEN sd.cs_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY sd.cs_net_paid DESC) AS purchase_rank
FROM sales_data sd
JOIN date_dim d_sold
    ON sd.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer c
    ON sd.cs_bill_customer_sk = c.c_customer_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND ws.web_mkt_id IN (1, 3, 5)
  AND ws.web_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_link_count > 15
          AND wp.wp_creation_date_sk = d_sold.d_date_sk
    )
ORDER BY purchase_rank
LIMIT 100
