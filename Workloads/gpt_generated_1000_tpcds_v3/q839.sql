WITH inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
item_sales_agg AS (
    SELECT ws_item_sk,
           SUM(ws_net_paid_inc_tax) AS total_ws_net_paid_inc_tax,
           AVG(ws_net_paid_inc_tax) AS avg_ws_net_paid_inc_tax
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    sm.sm_type AS ship_mode_type,
    ca_bill.ca_city AS bill_city,
    cd_bill.cd_gender AS bill_gender,
    cs.cs_quantity,
    cs.cs_net_paid,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    ws.ws_quantity,
    ws.ws_net_paid_inc_tax,
    inv_agg.total_qty_on_hand,
    ws_agg.total_ws_net_paid_inc_tax,
    RANK() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_net_paid_inc_tax DESC) AS ws_net_paid_rank,
    CASE
        WHEN ws.ws_net_paid_inc_tax > ws_agg.avg_ws_net_paid_inc_tax * 2 THEN 'High'
        WHEN ws.ws_net_paid_inc_tax > ws_agg.avg_ws_net_paid_inc_tax THEN 'Medium'
        ELSE 'Low'
    END AS sales_performance_category,
    EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_channel_radio = 'N'
    ) AS promo_has_radio_channel,
    (SELECT MAX(p2.p_cost)
     FROM promotion p2
     WHERE p2.p_item_sk = i.i_item_sk) AS max_promo_cost
FROM item i
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
   AND p.p_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN customer_address ca_bill
    ON ca_bill.ca_address_sk = cs.cs_bill_addr_sk
JOIN customer_demographics cd_bill
    ON cd_bill.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN web_site we
    ON we.web_site_sk = ws.ws_web_site_sk
JOIN inventory_agg inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
JOIN item_sales_agg ws_agg
    ON ws_agg.ws_item_sk = i.i_item_sk
WHERE
    p.p_channel_radio = 'N'
    AND we.web_company_name IN ('anti', 'pri')
    AND i.i_brand_id = 5
    AND ws.ws_ext_list_price > 5000
ORDER BY ws.ws_net_paid_inc_tax DESC
LIMIT 100
