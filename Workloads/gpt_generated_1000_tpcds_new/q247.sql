WITH agg_inventory AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand,
        MAX(inv_quantity_on_hand) AS max_qty_on_hand
    FROM inventory
    WHERE inv_date_sk = 2450969
    GROUP BY inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_state,
    ca.ca_city,
    p.p_promo_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(sr.sr_net_loss) AS avg_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MIN(ss.ss_sold_date_sk) AS first_sale_date_sk,
    MAX(ss.ss_sold_date_sk) AS last_sale_date_sk,
    ai.total_qty_on_hand,
    ai.max_qty_on_hand
FROM store_sales ss
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
INNER JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_store_sk = s.s_store_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
INNER JOIN catalog_returns cr
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   AND cr.cr_returning_addr_sk = ca.ca_address_sk
INNER JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
INNER JOIN agg_inventory ai
    ON ai.inv_warehouse_sk = w.w_warehouse_sk
WHERE s.s_store_id IN ('AAAAAAAAACAAAAAA','AAAAAAAABAAAAAAA')
  AND s.s_gmt_offset = -5.00
  AND ca.ca_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND w.w_state = 'TX'
  AND ss.ss_quantity > (
        SELECT MAX(inv_quantity_on_hand)
        FROM inventory
        WHERE inv_warehouse_sk = 1
    )
  AND EXISTS (
        SELECT 1
        FROM catalog_returns crx
        WHERE crx.cr_order_number = ss.ss_ticket_number
    )
GROUP BY
    s.s_store_id,
    s.s_state,
    ca.ca_city,
    p.p_promo_name,
    ai.total_qty_on_hand,
    ai.max_qty_on_hand
ORDER BY total_sales DESC
LIMIT 100
