WITH inventory_by_item_date AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_brand,
    ss.ss_store_sk,
    p.p_promo_id,
    cc.cc_name,
    cp.cp_catalog_page_number,
    wp.wp_url,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    MAX(inv.total_on_hand) AS max_inventory_on_hand,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN inventory_by_item_date inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws_outer
    ON ws_outer.ws_item_sk = i.i_item_sk
   AND ws_outer.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
    ON ws_outer.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_date >= DATE '2001-01-01'
  AND d.d_date < DATE '2001-02-01'
  AND i.i_brand = 'Brand#12'
  AND ca_ss.ca_state = 'GA'
  AND ss.ss_ticket_number NOT IN (
        SELECT ws_sub.ws_order_number
        FROM web_sales ws_sub
        WHERE ws_sub.ws_quantity > 500
    )
GROUP BY
    d.d_date,
    i.i_item_id,
    i.i_brand,
    ss.ss_store_sk,
    p.p_promo_id,
    cc.cc_name,
    cp.cp_catalog_page_number,
    wp.wp_url
ORDER BY
    total_net_paid DESC,
    d.d_date ASC
LIMIT 100
