WITH sales_with_page AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_description,
        i.i_product_name,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '([0-9]{3,})', 1) AS extracted_digits,
        CASE WHEN cs.cs_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_tier
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cp.cp_description LIKE '%promotion%'
      AND regexp_like(cp.cp_description, '(?i)discount|sale')
)
SELECT
    d.d_year,
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    COUNT(DISTINCT swp.extracted_digits) AS distinct_digit_codes,
    SUM(swp.cs_net_paid) AS total_net_paid,
    SUM(swp.cs_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(swp.cs_net_profit) > 10000 THEN 'Very High'
        WHEN SUM(swp.cs_net_profit) > 5000 THEN 'High'
        ELSE 'Medium/Low'
    END AS profit_category
FROM sales_with_page swp
JOIN date_dim d ON swp.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON swp.cs_bill_customer_sk = c.c_customer_sk
GROUP BY d.d_year, c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_net_profit DESC
LIMIT 100
