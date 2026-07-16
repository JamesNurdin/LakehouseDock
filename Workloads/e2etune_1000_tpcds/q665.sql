WITH store_gender_sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_country = 'United States'
      AND ca.ca_state = 'CA'
      AND cd.cd_education_status = 'College'
      AND ss.ss_sold_date_sk BETWEEN 2450900 AND 2450999
    GROUP BY ss.ss_store_sk, s.s_store_name, s.s_state, cd.cd_gender
)
SELECT
    sgs.s_state,
    sgs.s_store_name,
    sgs.cd_gender,
    sgs.total_profit,
    sgs.total_quantity,
    sgs.avg_net_paid,
    sgs.total_profit / NULLIF(sgs.total_net_paid, 0) AS profit_margin,
    RANK() OVER (PARTITION BY sgs.s_state ORDER BY (sgs.total_profit / NULLIF(sgs.total_net_paid, 0)) DESC) AS profit_margin_rank
FROM store_gender_sales sgs
WHERE sgs.total_quantity > 100
ORDER BY sgs.s_state, profit_margin_rank
