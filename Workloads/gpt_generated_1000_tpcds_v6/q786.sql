WITH sales_returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_state AS state,
        cd.cd_gender AS gender,
        ca.ca_gmt_offset AS gmt_offset,
        ss.ss_sold_date_sk AS sold_date_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_tickets,
        AVG(ss.ss_quantity) AS avg_quantity,
        MIN(ss.ss_net_profit) AS min_net_profit,
        MAX(ss.ss_net_profit) AS max_net_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_customer_sk = c.c_customer_sk
           AND sr.sr_cdemo_sk = cd.cd_demo_sk
           AND sr.sr_addr_sk = ca.ca_address_sk
           AND sr.sr_store_sk = s.s_store_sk
    WHERE
        s.s_state = 'CA'
        AND ca.ca_gmt_offset = -5.00
        AND c.c_birth_year BETWEEN 1970 AND 1980
        AND sr.sr_refunded_cash > 100.00
        AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        cd.cd_gender,
        ca.ca_gmt_offset,
        ss.ss_sold_date_sk
    HAVING
        SUM(ss.ss_net_paid) > 1000
)
SELECT
    store_id,
    store_name,
    state,
    gender,
    gmt_offset,
    sold_date_sk,
    total_net_paid,
    total_refunded_cash,
    cnt_tickets,
    avg_quantity,
    min_net_profit,
    max_net_profit,
    SUM(total_net_paid) OVER (PARTITION BY state ORDER BY sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_state_net_paid,
    RANK() OVER (PARTITION BY state ORDER BY total_net_paid DESC) AS net_paid_rank
FROM sales_returns_agg
ORDER BY total_net_paid DESC
LIMIT 100
