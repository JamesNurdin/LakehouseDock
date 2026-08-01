WITH filtered_sales AS (
    SELECT
        s.s_store_name AS s_store_name,
        d.d_year AS d_year,
        i.i_brand AS i_brand,
        i.i_item_desc AS i_item_desc,
        i.i_item_id AS i_item_id,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
        ss.ss_net_paid,
        ss.ss_net_profit,
        c.c_email_address,
        SUBSTR(c.c_email_address, 1, 5) AS email_prefix,
        ca.ca_country,
        hd.hd_income_band_sk,
        REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS item_code,
        CONCAT(i.i_brand, ' ', i.i_item_desc) AS full_item_desc
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND c.c_email_address LIKE '%@%.com'
      AND NOT c.c_email_address LIKE 'test%@%'
      AND ca.ca_country = 'United States'
)
SELECT
    s_store_name,
    d_year,
    i_brand,
    profit_category,
    COUNT(*) AS sale_count,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(ss_net_profit) AS avg_net_profit,
    MIN(email_prefix) AS sample_email_prefix,
    MAX(item_code) AS sample_item_code,
    MAX(full_item_desc) AS sample_full_item_desc
FROM filtered_sales
GROUP BY s_store_name, d_year, i_brand, profit_category
HAVING SUM(ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
