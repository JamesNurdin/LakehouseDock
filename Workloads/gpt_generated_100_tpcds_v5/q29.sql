/* Goal: Calculate total web sales profit by customer birth country and year for Japanese customers, rank the groups by profit, and compare each group’s profit to the overall average profit. */
WITH filtered_sales AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_net_profit,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_promo_sk
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk BETWEEN 2451540 AND 2452227
      AND ws.ws_promo_sk IN (220, 388, 771)
      AND ws.ws_quantity > 1
),
joined AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_country,
        c.c_birth_year,
        wp.wp_type,
        ws.ws_net_profit
    FROM filtered_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_birth_country = 'JAPAN'
      AND c.c_birth_year BETWEEN 1950 AND 1960
      AND wp.wp_type = 'product'
)
SELECT
    j.c_birth_country,
    j.c_birth_year,
    CASE WHEN GROUPING(j.c_birth_year) = 1 THEN 'ALL_YEARS' ELSE CAST(j.c_birth_year AS VARCHAR) END AS birth_year_group,
    SUM(j.ws_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    RANK() OVER (ORDER BY SUM(j.ws_net_profit) DESC) AS profit_rank,
    (SELECT AVG(ws_net_profit) FROM web_sales) AS avg_profit_overall
FROM joined j
GROUP BY GROUPING SETS (
    (j.c_birth_country, j.c_birth_year),
    (j.c_birth_country),
    ()
)
ORDER BY profit_rank
LIMIT 100
