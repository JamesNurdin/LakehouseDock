WITH
    sales AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_cdemo_sk,
            ss.ss_net_profit,
            ss.ss_quantity,
            ss.ss_item_sk
        FROM store_sales ss
        WHERE ss.ss_net_profit > 0
    ),
    date_info AS (
        SELECT d_date_sk, d_year, d_month_seq, d_date
        FROM date_dim
        WHERE d_year = 2001
    ),
    cust_demo AS (
        SELECT cd_demo_sk,
               cd_education_status,
               cd_dep_college_count,
               cd_purchase_estimate
        FROM customer_demographics
        WHERE cd_education_status LIKE '%College%'
          AND cd_dep_college_count >= 1
    ),
    catalog AS (
        SELECT cp_catalog_page_sk,
               cp_catalog_page_id,
               cp_type,
               cp_start_date_sk,
               cp_end_date_sk,
               regexp_extract(cp_catalog_page_id, '[A-Z]{9}([A-Z])', 1) AS id_last_char
        FROM catalog_page
        WHERE regexp_like(cp_catalog_page_id, '^A{8,}B')
          AND cp_type IN ('quarterly', 'monthly')
    )
SELECT
    c.cp_type,
    c.id_last_char,
    d.d_year,
    CONCAT(c.cp_type, '-', c.id_last_char) AS type_code,
    SUM(s.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT s.ss_item_sk) AS distinct_items_sold,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM sales s
JOIN date_info d       ON s.ss_sold_date_sk = d.d_date_sk
JOIN cust_demo cd      ON s.ss_cdemo_sk = cd.cd_demo_sk
JOIN catalog c         ON c.cp_start_date_sk = d.d_date_sk
GROUP BY c.cp_type, c.id_last_char, d.d_year, CONCAT(c.cp_type, '-', c.id_last_char)
ORDER BY total_net_profit DESC
LIMIT 100
