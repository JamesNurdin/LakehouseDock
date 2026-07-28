WITH store_agg AS (
   SELECT
       d.d_year,
       p.p_promo_name,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS orders,
       SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
       AVG(ss.ss_quantity) AS avg_quantity,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 1200 AND 1240
     AND p.p_discount_active = 'Y'
     AND p.p_channel_email = 'Y'
     AND ss.ss_quantity > 50
     AND ss.ss_net_paid > 1000
     AND EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_promo_sk = ss.ss_promo_sk
           AND p2.p_purpose = 'Clearance'
     )
     AND (r.r_reason_desc LIKE '%price%' OR r.r_reason_desc IS NULL)
   GROUP BY d.d_year, p.p_promo_name
   HAVING SUM(ss.ss_net_profit) > 0
),
web_agg AS (
   SELECT
       d.d_year,
       p.p_promo_name,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(DISTINCT ws.ws_order_number) AS orders,
       AVG(ws.ws_quantity) AS avg_quantity,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   WHERE d.d_year = 2001
     AND p.p_discount_active = 'Y'
     AND p.p_channel_email = 'Y'
     AND ws.ws_quantity > 20
     AND ws.ws_ext_wholesale_cost > 5000
     AND w.web_state = 'CA'
   GROUP BY d.d_year, p.p_promo_name
   HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    d_year,
    p_promo_name,
    total_net_paid,
    total_net_profit,
    orders,
    total_return_amt,
    avg_quantity,
    profit_rank,
    channel
FROM (
    SELECT
        d_year,
        p_promo_name,
        total_net_paid,
        total_net_profit,
        orders,
        total_return_amt,
        avg_quantity,
        profit_rank,
        'store' AS channel
    FROM store_agg
    UNION ALL
    SELECT
        d_year,
        p_promo_name,
        total_net_paid,
        total_net_profit,
        orders,
        NULL AS total_return_amt,
        avg_quantity,
        profit_rank,
        'web' AS channel
    FROM web_agg
) combined
ORDER BY d_year DESC, total_net_profit DESC
LIMIT 100
