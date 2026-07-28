WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_list_price,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        CASE
            WHEN ss.ss_net_paid_inc_tax >= 20000 THEN 'HIGH'
            WHEN ss.ss_net_paid_inc_tax >= 5000  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS spending_category
    FROM
        store_sales ss
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 2451000 AND 2453000
        AND ss.ss_net_paid_inc_tax > 1000
        AND ss.ss_quantity >= 2
        AND ss.ss_list_price BETWEEN 50 AND 200
        AND cd.cd_gender = 'M'
        AND cd.cd_marital_status IN ('M', 'S')
        AND cd.cd_dep_employed_count >= 2
        AND cd.cd_dep_college_count >= 1
)
SELECT
    fs.ss_sold_date_sk,
    fs.ss_ticket_number,
    fs.ss_quantity,
    fs.ss_list_price,
    fs.ss_net_paid_inc_tax,
    fs.ss_net_profit,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.spending_category,
    ROW_NUMBER() OVER (PARTITION BY fs.cd_gender ORDER BY fs.ss_net_paid_inc_tax DESC) AS gender_rank,
    RANK() OVER (ORDER BY fs.ss_net_paid_inc_tax DESC) AS overall_rank
FROM
    filtered_sales fs
ORDER BY
    overall_rank
LIMIT 100
