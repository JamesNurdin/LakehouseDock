/*
Goal: Produce a deep‑join analytical report that brings together all 16 TPC‑DS tables, sampling catalog sales, intersecting common item keys between catalog and web sales, and showing per‑store‑hour‑category profit metrics with a loss/profit flag. The query uses explicit joins, a FULL OUTER JOIN, a TABLESAMPLE, an INTERSECT CTE, a CASE expression, grouping, ordering, pagination and LIMIT 100.
*/
WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
intersect_items AS (
    SELECT cs_item_sk AS item_sk FROM catalog_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
)
SELECT
    s1.s_store_name,
    t1.t_hour,
    i1.i_category,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
    SUM(COALESCE(cs.cs_net_profit, 0)) AS total_catalog_profit,
    CASE WHEN SUM(COALESCE(sr.sr_net_loss, 0)) > 0 THEN 'Loss' ELSE 'Profit' END AS store_return_status
FROM store_sales ss
JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
JOIN customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
JOIN store s1 ON ss.ss_store_sk = s1.s_store_sk
JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
FULL OUTER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
JOIN cs_sample cs ON cs.cs_item_sk = i1.i_item_sk
JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN ship_mode sm3 ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk
JOIN inventory inv ON inv.inv_item_sk = i1.i_item_sk
JOIN intersect_items ii ON i1.i_item_sk = ii.item_sk
WHERE t1.t_sub_shift = 'afternoon'
GROUP BY s1.s_store_name, t1.t_hour, i1.i_category
ORDER BY total_store_profit DESC
OFFSET 0 LIMIT 100
