WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        p.p_promo_id,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
    FROM tpcds.customer c
    JOIN tpcds.store_sales ss
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    WHERE ss.ss_sales_price > 50
      AND ss.ss_quantity >= 2
      AND ws.ws_net_paid_inc_tax > 1000
      AND ws.ws_ext_ship_cost < 500
      AND p.p_channel_catalog = 'N'
    GROUP BY c.c_customer_sk, c.c_customer_id, p.p_promo_id
)
SELECT
    cs.c_customer_id,
    cs.p_promo_id,
    cs.store_net_paid,
    cs.web_net_paid,
    (cs.store_net_paid + cs.web_net_paid) AS total_net_paid,
    CASE WHEN cs.store_net_paid > cs.web_net_paid THEN 'Store' ELSE 'Web' END AS higher_channel,
    ROW_NUMBER() OVER (PARTITION BY cs.p_promo_id ORDER BY (cs.store_net_paid + cs.web_net_paid) DESC) AS promo_rank
FROM customer_sales cs
WHERE (cs.store_net_paid + cs.web_net_paid) > (
    SELECT AVG(inner_total)
    FROM (
        SELECT (store_net_paid + web_net_paid) AS inner_total
        FROM customer_sales
    ) t
)
ORDER BY cs.p_promo_id, promo_rank
LIMIT 100
