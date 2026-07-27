WITH sales_filtered AS (
    SELECT
        s.s_store_name AS s_store_name,
        i.i_brand AS i_brand,
        i.i_formulation AS i_formulation,
        ca.ca_city AS ca_city,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_sold_date_sk AS ss_sold_date_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ca.ca_city LIKE 'S%'
      AND d.d_year = 2000
      AND regexp_like(i.i_formulation, '\\d{3}')
)
SELECT
    s_store_name,
    i_brand,
    CASE
        WHEN CAST(regexp_extract(i_formulation, '(\\d+)', 1) AS integer) >= 500000 THEN 'HighNum'
        ELSE 'LowNum'
    END AS formulation_category,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(*) AS transaction_count,
    CONCAT(s_store_name, ' - ', i_brand) AS store_brand_concat
FROM sales_filtered
GROUP BY
    s_store_name,
    i_brand,
    CASE
        WHEN CAST(regexp_extract(i_formulation, '(\\d+)', 1) AS integer) >= 500000 THEN 'HighNum'
        ELSE 'LowNum'
    END
ORDER BY total_net_profit DESC
LIMIT 100
