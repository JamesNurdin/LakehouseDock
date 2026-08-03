/*
Goal: Identify customers' sales performance and return behavior by joining all nine TPC‑DS tables, using multiple aliases for date and address dimensions, aggregating with GROUPING SETS, applying a CASE‑based sales category, and limiting to the top 100 records.
*/
WITH d_sold AS (
    SELECT d_date_sk, d_year
    FROM date_dim
),
 d_ship AS (
    SELECT d_date_sk, d_year
    FROM date_dim
),
 d_ret AS (
    SELECT d_date_sk, d_year
    FROM date_dim
)
SELECT
    c.c_customer_id,
    d_sold.d_year          AS sold_year,
    d_ship.d_year          AS ship_year,
    SUM(cs.cs_net_paid)   AS total_net_paid,
    AVG(cs.cs_quantity)   AS avg_quantity,
    CASE
        WHEN SUM(cs.cs_net_paid) > (
            SELECT AVG(cs2.cs_net_paid)
            FROM catalog_sales cs2
        ) THEN 'High'
        ELSE 'Low'
    END                    AS sales_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_net_loss)   AS total_return_loss
FROM catalog_sales cs
JOIN d_sold      ON cs.cs_sold_date_sk   = d_sold.d_date_sk
JOIN d_ship      ON cs.cs_ship_date_sk   = d_ship.d_date_sk
JOIN customer    c   ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address      ca_bill ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode   sm      ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN store_returns sr    ON sr.sr_customer_sk    = c.c_customer_sk
JOIN d_ret       ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address      ca_ret ON sr.sr_addr_sk   = ca_ret.ca_address_sk
JOIN store       s       ON sr.sr_store_sk       = s.s_store_sk
GROUP BY GROUPING SETS (
    (c.c_customer_id, d_sold.d_year),
    (c.c_customer_id, d_ship.d_year)
)
ORDER BY total_net_paid DESC
LIMIT 100
