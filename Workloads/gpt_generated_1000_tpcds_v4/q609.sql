WITH base AS (
    SELECT
        ca.ca_state,
        p.p_promo_name,
        ss.ss_net_paid,
        ws.ws_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          AND wp.wp_type = 'content'
    )
      AND d.d_year = 2001
      AND ca.ca_state IN ('TX', 'CA')
      AND p.p_channel_event = 'N'
      AND p2.p_channel_event = 'N'
      AND ss.ss_quantity > 2
      AND ws.ws_quantity > 1
),
agg1 AS (
    SELECT
        ca_state,
        p_promo_name,
        SUM(ss_net_paid) AS sum_store_net,
        SUM(ws_net_paid) AS sum_web_net,
        SUM(ss_net_paid) + SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS txn_cnt
    FROM base
    GROUP BY ca_state, p_promo_name
),
agg2 AS (
    SELECT
        ca_state,
        AVG(total_net_paid) AS avg_total_net_paid,
        SUM(txn_cnt) AS total_txn_cnt
    FROM agg1
    GROUP BY ca_state
    HAVING AVG(total_net_paid) > 5000
)
SELECT
    ca_state,
    avg_total_net_paid,
    total_txn_cnt
FROM agg2
ORDER BY avg_total_net_paid DESC
LIMIT 100
