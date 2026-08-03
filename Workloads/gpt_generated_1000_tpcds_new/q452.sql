WITH
    ss_sample AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    intersect_items AS (
        SELECT ss_item_sk FROM ss_sample
        INTERSECT
        SELECT ws_item_sk FROM ws_sample
    )
SELECT
    i.i_category,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(*)               AS sales_cnt,
    AVG(ss.ss_quantity)    AS avg_quantity,
    MIN(ss.ss_net_paid)    AS min_net_paid,
    MAX(ss.ss_net_paid)    AS max_net_paid,
    AVG(lr.return_cnt)     AS avg_returns_per_sale
FROM ss_sample ss
JOIN intersect_items ii ON ss.ss_item_sk = ii.ss_item_sk
JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i              ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p         ON ss.ss_promo_sk = p.p_promo_sk
JOIN store st            ON ss.ss_store_sk = st.s_store_sk
JOIN customer c          ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r          ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN inventory inv     ON i.i_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
JOIN cs_sample cs          ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs       ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN ws_sample ws          ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm_ws       ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt
    FROM store_returns sr2
    WHERE sr2.sr_ticket_number = ss.ss_ticket_number
) lr
WHERE d.d_year = 2001
  AND t.t_hour BETWEEN 9 AND 17
  AND i.i_brand = 'Brand#12'
  AND p.p_discount_active = 'Y'
  AND cc.cc_state = 'CA'
  AND sm_ws.sm_type = 'AIR'
  AND inv.inv_quantity_on_hand > 0
GROUP BY CUBE (i.i_category, d.d_year)
ORDER BY total_net_paid DESC
LIMIT 100
