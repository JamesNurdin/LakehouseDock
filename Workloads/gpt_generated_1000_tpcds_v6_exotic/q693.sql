WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_date_sk,
          SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   WHERE inv_warehouse_sk IN (3, 8, 14)
   GROUP BY inv_item_sk, inv_date_sk
)
SELECT DISTINCT
    d_sales.d_date AS sale_date,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ws_agg.web_sales_amount,
    i.total_qty_on_hand,
    p.p_promo_name,
    r.r_reason_desc,
    DENSE_RANK() OVER (PARTITION BY d_sales.d_year ORDER BY ss.ss_net_paid DESC) AS profit_rank
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN inv_agg i
  ON i.inv_item_sk = ss.ss_item_sk
 AND i.inv_date_sk = d_sales.d_date_sk
JOIN (
    SELECT ws_item_sk,
           ws_sold_date_sk,
           SUM(ws_ext_sales_price) AS web_sales_amount,
           SUM(ws_net_profit) AS web_net_profit,
           ws_web_page_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450900 AND 2451150
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_web_page_sk
) ws_agg
  ON ws_agg.ws_item_sk = ss.ss_item_sk
 AND ws_agg.ws_sold_date_sk = d_sales.d_date_sk
JOIN web_page wp
  ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_sales.d_date_sk
 AND cr.cr_returned_time_sk = t_sales.t_time_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_catalog_start
  ON cp.cp_start_date_sk = d_catalog_start.d_date_sk
JOIN date_dim d_catalog_end
  ON cp.cp_end_date_sk = d_catalog_end.d_date_sk
JOIN date_dim d_web_ship
  ON ws_agg.ws_sold_date_sk = d_web_ship.d_date_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sales.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND cp.cp_type = 'monthly'
  AND wp.wp_max_ad_count >= 2
  AND r.r_reason_desc LIKE '%damage%'
  AND ss.ss_quantity > 1
  AND NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = ss.ss_item_sk
          AND inv.inv_date_sk = d_sales.d_date_sk
          AND inv.inv_quantity_on_hand > 0
    )
ORDER BY profit_rank, sale_date
LIMIT 100
