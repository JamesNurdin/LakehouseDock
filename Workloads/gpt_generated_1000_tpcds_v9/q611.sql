SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_education_status,
    p.p_promo_id,
    p.p_purpose,
    site.web_name,
    w.w_warehouse_id,
    w.w_city,
    inv_ltr.inv_quantity_on_hand,
    ws.ws_net_paid_inc_ship_tax,
    ws.ws_net_profit,
    CASE 
        WHEN ws.ws_ext_discount_amt > 500 THEN 'High'
        WHEN ws.ws_ext_discount_amt > 0 THEN 'Low'
        ELSE 'None'
    END AS discount_level,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    (SELECT avg(ws2.ws_net_paid)
     FROM web_sales ws2
     WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk) AS avg_warehouse_net_paid
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
      AND inv.inv_item_sk = ws.ws_item_sk
    ORDER BY inv.inv_date_sk DESC
    LIMIT 1
) AS inv_ltr
WHERE ws.ws_net_paid_inc_ship_tax > 1000
  AND p.p_channel_catalog = 'N'
  AND w.w_country = 'United States'
  AND c.c_preferred_cust_flag = 'Y'
  AND cd.cd_education_status = 'College'
  AND NOT EXISTS (
      SELECT 1
      FROM inventory i_low
      WHERE i_low.inv_warehouse_sk = w.w_warehouse_sk
        AND i_low.inv_quantity_on_hand < 5
  )
ORDER BY ws.ws_net_paid_inc_ship_tax DESC
LIMIT 100
