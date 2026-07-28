WITH joined_data AS (
    SELECT
        c1.c_customer_id,
        ca1.ca_city,
        p.p_promo_name,
        r.r_reason_desc,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        sr.sr_refunded_cash
    FROM store_sales ss
    JOIN customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
    JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca3 ON c1.c_current_addr_sk = ca3.ca_address_sk
    JOIN store_sales ss_item ON sr.sr_item_sk = ss_item.ss_item_sk
    WHERE ss.ss_net_profit IS NOT NULL
),
agg AS (
    SELECT
        c_customer_id,
        ca_city,
        p_promo_name,
        r_reason_desc,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS ticket_cnt,
        AVG(sr_refunded_cash) AS avg_refunded_cash
    FROM joined_data
    GROUP BY c_customer_id, ca_city, p_promo_name, r_reason_desc
)
SELECT
    c_customer_id,
    ca_city,
    p_promo_name,
    r_reason_desc,
    total_net_profit,
    ticket_cnt,
    avg_refunded_cash,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
