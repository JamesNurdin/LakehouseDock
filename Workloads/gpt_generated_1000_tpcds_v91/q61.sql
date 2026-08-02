WITH date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1 AND 12
      AND d_week_seq BETWEEN 10 AND 20
      AND d_holiday = 'N'
),
warehouse_filtered AS (
    SELECT *
    FROM warehouse
    WHERE w_state IN ('GA', 'MO')
),
promotion_filtered AS (
    SELECT *
    FROM promotion
    WHERE p_channel_tv = 'N'
),
reason_filtered AS (
    SELECT *
    FROM reason
    WHERE r_reason_desc IS NOT NULL
),
inventory_sub AS (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 100
)
SELECT
    d.d_year,
    w.w_state,
    ca.ca_state AS customer_state,
    seg.segment,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_status,
    SUM(COALESCE(cs.cs_net_profit, 0)) AS catalog_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS web_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss,
    SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_inventory,
    COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
FROM date_filtered d
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN warehouse_filtered w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion_filtered p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason_filtered r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp_ws
    ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp_wr
    ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
LEFT JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
CROSS JOIN (VALUES ('SEG_A'), ('SEG_B')) AS seg(segment)
WHERE cs.cs_item_sk IN (SELECT inv_item_sk FROM inventory_sub)
  AND ca.ca_state = 'CA'
  AND p.p_discount_active = 'N'
  AND r.r_reason_id LIKE 'AAAA%'
GROUP BY CUBE(d.d_year, w.w_state, ca.ca_state, p.p_discount_active, seg.segment)
ORDER BY d.d_year DESC, w.w_state, catalog_profit DESC
LIMIT 100
