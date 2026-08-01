WITH avg_price AS (
    SELECT avg(ss_ext_sales_price) AS val FROM store_sales
),
high_qty_items AS (
    SELECT ss_item_sk AS item_sk FROM store_sales WHERE ss_quantity > 10
    UNION ALL
    SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 10
)
SELECT
    ss.ss_sold_date_sk,
    ss.ss_ticket_number,
    s.s_store_name,
    i.i_item_id,
    i.i_category,
    p.p_promo_name,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    CASE
        WHEN ss.ss_ext_sales_price > (SELECT val FROM avg_price) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS price_category,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    (
        SELECT max(sr2.sr_return_quantity)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ss.ss_item_sk
    ) AS max_return_qty_for_item,
    cr.cr_return_amount,
    r.r_reason_desc,
    sm.sm_carrier,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    wsite.web_name
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
    AND ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr ON ss.ss_item_sk = cr.cr_item_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    ss.ss_quantity > 1
    AND i.i_current_price BETWEEN 100 AND 5000
    AND s.s_state = 'CA'
    AND cp.cp_department = 'Electronics'
    AND inv.inv_quantity_on_hand > 0
    AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          AND sr2.sr_return_quantity > 0
    )
    AND i.i_item_id IN (
        SELECT i2.i_item_id FROM item i2 WHERE i2.i_color = 'Red'
    )
    AND ss.ss_ext_sales_price > (SELECT val FROM avg_price)
    AND ss.ss_item_sk IN (
        SELECT item_sk FROM high_qty_items
    )
ORDER BY s.s_store_name, profit_rank
LIMIT 100
