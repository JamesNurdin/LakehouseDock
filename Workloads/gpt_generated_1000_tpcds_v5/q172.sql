WITH sales_cte AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2451462 AND 2451858
)
SELECT
    s.s_store_id,
    s.s_division_name,
    cd.cd_gender,
    SUM(sales_cte.ss_ext_sales_price) AS total_sales,
    AVG(sales_cte.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT sales_cte.ss_ticket_number) AS unique_tickets,
    MIN(sales_cte.ss_sold_date_sk) AS first_sold_date_sk,
    MAX(sales_cte.ss_sold_date_sk) AS last_sold_date_sk
FROM sales_cte
JOIN customer c
    ON sales_cte.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sales_cte.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sales_cte.ss_store_sk = s.s_store_sk
WHERE s.s_hours = '8AM-4PM'
  AND cd.cd_marital_status = 'M'
GROUP BY s.s_store_id, s.s_division_name, cd.cd_gender
ORDER BY total_sales DESC
LIMIT 100
