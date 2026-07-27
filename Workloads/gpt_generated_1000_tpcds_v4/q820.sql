WITH inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ib.ib_lower_bound,
    hd.hd_vehicle_count,
    inv.total_qty,
    SUM(ss.ss_net_profit) AS store_total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
    CASE
        WHEN SUM(ss.ss_net_profit) / NULLIF(COUNT(DISTINCT ss.ss_ticket_number), 0) > (
            SELECT AVG(ss2.ss_net_profit)
            FROM store_sales ss2
            WHERE ss2.ss_item_sk = i.i_item_sk
        ) THEN 'Above Avg Item Profit'
        ELSE 'Below Avg Item Profit'
    END AS profit_category,
    (
        SELECT SUM(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
    ) AS total_web_profit
FROM store_sales ss
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN inventory_agg inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 50000
  AND hd.hd_vehicle_count > 0
  AND i.i_current_price > 10
  AND inv.total_qty > 500
GROUP BY
    i.i_item_id,
    i.i_product_name,
    ib.ib_lower_bound,
    hd.hd_vehicle_count,
    inv.total_qty,
    i.i_item_sk
ORDER BY store_total_profit DESC
LIMIT 100
