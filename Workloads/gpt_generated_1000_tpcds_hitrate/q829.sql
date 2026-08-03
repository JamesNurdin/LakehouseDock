WITH item_in_sales AS (
        SELECT ss.ss_item_sk AS i_item_sk
        FROM store_sales ss
        WHERE ss.ss_quantity > 5
    ),
    item_in_web AS (
        SELECT ws.ws_item_sk AS i_item_sk
        FROM web_sales ws
        WHERE ws.ws_quantity > 5
    ),
    common_items AS (
        SELECT i_item_sk FROM item_in_sales
        INTERSECT
        SELECT i_item_sk FROM item_in_web
    )
SELECT
    i.i_brand,
    hd.hd_dep_count,
    period_tbl.period,
    CASE WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS revenue_category,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(ss.ss_quantity) AS min_qty,
    MAX(ss.ss_quantity) AS max_qty
FROM store_sales ss
JOIN common_items ci ON ss.ss_item_sk = ci.i_item_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN promotion promo ON ss.ss_promo_sk = promo.p_promo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_time_sk = td.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
CROSS JOIN (SELECT 'AM' AS period UNION ALL SELECT 'PM' AS period) AS period_tbl
WHERE i.i_class_id IN (15, 5)
  AND ca.ca_state = 'CA'
  AND ib.ib_lower_bound >= 50000
  AND td.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_quantity > 0
    )
GROUP BY GROUPING SETS (
        (i.i_brand, hd.hd_dep_count, period_tbl.period),
        (i.i_brand, period_tbl.period),
        (period_tbl.period)
    )
ORDER BY total_net_paid DESC
LIMIT 100
