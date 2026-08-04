WITH ss_agg AS (
    SELECT ss_item_sk,
           ss_store_sk,
           SUM(ss_ext_sales_price) AS total_store_sales,
           COUNT(*) AS cnt_store_sales
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2450825
      AND ss_quantity > 1
    GROUP BY ss_item_sk, ss_store_sk
)
SELECT DISTINCT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    w.w_warehouse_name,
    td.t_hour,
    cd.cd_gender,
    hd.hd_buy_potential,
    ss_agg.total_store_sales,
    ss_agg.cnt_store_sales,
    ws.ws_net_profit,
    (
        SELECT MAX(inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
    ) AS max_inventory_qty
FROM ss_agg
JOIN store_sales ss
    ON ss.ss_item_sk = ss_agg.ss_item_sk
   AND ss.ss_store_sk = ss_agg.ss_store_sk
JOIN item i
    ON i.i_item_sk = ss.ss_item_sk
JOIN promotion p
    ON p.p_promo_sk = ss.ss_promo_sk
JOIN time_dim td
    ON td.t_time_sk = ss.ss_sold_time_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = ss.ss_cdemo_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = ss.ss_hdemo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN web_site webs
    ON webs.web_site_sk = ws.ws_web_site_sk
LEFT JOIN warehouse w
    ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '5000-9999'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_amt > 1000
      )
ORDER BY ss_agg.total_store_sales DESC
OFFSET 0 LIMIT 100
