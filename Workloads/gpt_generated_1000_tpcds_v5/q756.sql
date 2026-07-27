WITH base AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        ca_bill.ca_address_id AS bill_address_id,
        cd_bill.cd_gender AS bill_gender,
        t_cs.t_hour,
        t_cs.t_minute,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_ticket_number,
        s.s_store_id,
        s.s_store_name,
        s.s_store_sk,
        ca_store.ca_address_id AS store_address_id,
        cd_store.cd_gender AS store_gender,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_refunded_cash AS sr_refunded_cash
    FROM catalog_sales cs
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t_cs.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_store
        ON ss.ss_addr_sk = ca_store.ca_address_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t_cs.t_time_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t_cs.t_time_sk
)
SELECT
    s_store_id,
    s_store_name,
    t_hour,
    t_minute,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    SUM(sr_refunded_cash) AS total_refunded_cash,
    (SUM(cs_net_paid) + SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(sr_refunded_cash)) AS total_net,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s_store_sk
    ) AS avg_store_net_paid
FROM base
GROUP BY
    s_store_id,
    s_store_name,
    t_hour,
    t_minute,
    s_store_sk
HAVING (SUM(cs_net_paid) + SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(sr_refunded_cash)) >
       (
           SELECT AVG(ss3.ss_net_paid)
           FROM store_sales ss3
           WHERE ss3.ss_store_sk = s_store_sk
       )
ORDER BY total_net DESC
LIMIT 100
