WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_location_type,
        cd.cd_marital_status,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT wp.wp_url) AS distinct_pages_visited
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ca.ca_location_type = 'condo'
      AND cd.cd_marital_status = 'M'
      AND ss.ss_store_sk IN (235, 46, 181)
      AND ss.ss_ext_wholesale_cost BETWEEN 1000 AND 8000
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_location_type,
        cd.cd_marital_status,
        ss.ss_store_sk
)
SELECT
    ss_store_sk,
    AVG(total_net_profit) AS avg_total_net_profit,
    SUM(sales_cnt) AS total_sales,
    AVG(distinct_pages_visited) AS avg_distinct_pages
FROM sales_agg
GROUP BY ss_store_sk
HAVING AVG(total_net_profit) > 5000
ORDER BY avg_total_net_profit DESC
LIMIT 100
