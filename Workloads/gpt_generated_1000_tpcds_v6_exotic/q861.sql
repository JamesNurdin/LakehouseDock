WITH sales_by_store_promo AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          WHERE cp.cp_start_date_sk = d.d_date_sk
            AND cp.cp_type = 'Printed'
      )
    GROUP BY s.s_store_id, p.p_promo_id, d.d_year
)
SELECT
    s_store_id,
    avg_total_net_paid,
    avg_total_net_profit
FROM (
    SELECT
        s_store_id,
        AVG(store_net_paid + web_net_paid) AS avg_total_net_paid,
        AVG(store_net_profit + web_net_profit) AS avg_total_net_profit
    FROM sales_by_store_promo
    GROUP BY s_store_id
) agg
WHERE avg_total_net_paid > 1000
ORDER BY avg_total_net_paid DESC
LIMIT 100
