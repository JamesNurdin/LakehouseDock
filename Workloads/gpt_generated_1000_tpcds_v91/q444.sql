WITH
    -- scalar subquery for average item price (used later)
    avg_price_sub AS (
        SELECT AVG(i2.i_current_price) AS avg_price FROM item i2
    )
SELECT
    s.s_store_name,
    d.d_year,
    p.p_promo_name,
    i.i_category,
    COUNT(DISTINCT c.c_customer_id)                      AS distinct_customers,
    SUM(ss.ss_net_paid)                                 AS total_store_sales,
    SUM(ss.ss_net_profit)                               AS total_store_profit,
    SUM(COALESCE(sr.sr_net_loss, 0))                    AS total_store_return_loss,
    SUM(COALESCE(ws.ws_net_paid, 0))                    AS total_web_sales,
    SUM(COALESCE(ws.ws_net_profit, 0))                  AS total_web_profit,
    COUNT(DISTINCT cc.cc_name)                          AS call_center_count,
    COUNT(DISTINCT wsite.web_name)                      AS web_site_count,
    (SELECT avg_price FROM avg_price_sub)              AS avg_item_price
FROM store_sales ss
FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN store s_ret
    ON sr.sr_store_sk = s_ret.s_store_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim wdate
    ON wsite.web_open_date_sk = wdate.d_date_sk
JOIN date_dim wpdate
    ON wp.wp_access_date_sk = wpdate.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = ss.ss_promo_sk
      AND p2.p_cost > 1000
)
GROUP BY s.s_store_name, d.d_year, p.p_promo_name, i.i_category
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_store_sales DESC
LIMIT 100
