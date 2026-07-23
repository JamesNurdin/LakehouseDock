WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        i.i_category,
        i.i_product_name,
        d.d_year,
        d.d_month_seq,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cp.cp_description,
        sm.sm_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_product_name, '^[A-Z]{2}[0-9]{3}.*')
      AND c.c_last_name LIKE 'S%'
      AND cp.cp_type LIKE '%online%'
)
SELECT
    filtered_sales.d_year,
    filtered_sales.d_month_seq,
    filtered_sales.i_category,
    regexp_extract(filtered_sales.i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS product_code,
    SUBSTRING(filtered_sales.i_product_name, 1, 20) AS product_name_prefix,
    CONCAT(filtered_sales.c_first_name, ' ', filtered_sales.c_last_name) AS customer_name,
    SUM(filtered_sales.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    AVG(filtered_sales.cs_net_profit) AS avg_net_profit,
    SUM(filtered_sales.cs_net_profit) / (SELECT AVG(cs_net_profit) FROM catalog_sales) AS profit_vs_global_avg
FROM filtered_sales
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = filtered_sales.cs_item_sk
      AND cr.cr_order_number = filtered_sales.cs_order_number
)
GROUP BY
    filtered_sales.d_year,
    filtered_sales.d_month_seq,
    filtered_sales.i_category,
    regexp_extract(filtered_sales.i_product_name, '([A-Z]{2}[0-9]{3})', 1),
    SUBSTRING(filtered_sales.i_product_name, 1, 20),
    CONCAT(filtered_sales.c_first_name, ' ', filtered_sales.c_last_name)
HAVING SUM(filtered_sales.cs_net_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales)
ORDER BY total_net_profit DESC
LIMIT 100
