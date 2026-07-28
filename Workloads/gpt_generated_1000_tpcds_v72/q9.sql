WITH filtered_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_net_paid,
        ss.ss_wholesale_cost,
        ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_item_sk IN (251731, 107683)
      AND ss.ss_net_profit > 0
      AND ss.ss_quantity >= 1
      AND ss.ss_net_paid_inc_tax > 100
),
customer_with_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_email_address,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_dep_employed_count
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_employed_count >= 2
      AND c.c_email_address LIKE '%@%.org'
)
SELECT
    cwd.c_current_cdemo_sk,
    cwd.cd_gender,
    SUM(fs.ss_net_paid) AS total_net_paid,
    AVG(fs.ss_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT fs.ss_ticket_number) AS distinct_tickets,
    MAX(fs.ss_net_profit) AS max_net_profit,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_net_profit
FROM filtered_sales fs
JOIN customer_with_demo cwd
    ON fs.ss_customer_sk = cwd.c_customer_sk
   AND fs.ss_cdemo_sk = cwd.cd_demo_sk
GROUP BY ROLLUP (cwd.c_current_cdemo_sk, cwd.cd_gender)
ORDER BY total_net_paid DESC
LIMIT 100
