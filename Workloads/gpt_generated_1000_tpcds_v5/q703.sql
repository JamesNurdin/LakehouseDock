WITH sales_by_bill_addr AS (
    SELECT
        cs_bill_addr_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        MAX(cs_ext_sales_price) AS max_ext_sales,
        MIN(cs_ext_sales_price) AS min_ext_sales
    FROM catalog_sales
    WHERE cs_net_profit > 0
    GROUP BY cs_bill_addr_sk
)
SELECT
    ca.ca_address_sk,
    concat(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
    ca.ca_city,
    ca.ca_state,
    sb.total_profit,
    sb.sales_cnt,
    regexp_like(ca.ca_street_name, '^Elm|Maple') AS is_elm_or_maple,
    regexp_extract(ca.ca_street_name, '(\\w+)$') AS street_name_suffix,
    (
        SELECT AVG(cs_net_profit)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_bill_addr_sk = ca.ca_address_sk
    ) AS avg_profit_per_sale
FROM sales_by_bill_addr sb
JOIN customer_address ca
    ON sb.cs_bill_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_city LIKE 'A%'
    AND sb.total_profit > (
        SELECT AVG(total_profit) FROM sales_by_bill_addr
    )
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_addr_sk = ca.ca_address_sk
          AND cs2.cs_list_price > 200
    )
ORDER BY sb.total_profit DESC
LIMIT 100
