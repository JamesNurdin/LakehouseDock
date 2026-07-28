WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    w.w_warehouse_name,
    cd_sales.cd_gender,
    SUM(cs.cs_ext_sales_price)                     AS total_sales,
    SUM(cr.cr_return_amount)                       AS total_return_amount,
    SUM(ws.ws_ext_sales_price)                     AS web_total_sales,
    inv_agg.total_on_hand,
    COUNT(DISTINCT cs.cs_order_number)            AS distinct_orders,
    AVG(p.p_cost)                                  AS avg_promo_cost,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
    )                                              AS max_item_promo_cost
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_sales
    ON cs.cs_bill_cdemo_sk = cd_sales.cd_demo_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_brand_id = 4
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 5000
      )
GROUP BY i.i_item_id,
         i.i_item_sk,
         i.i_category,
         w.w_warehouse_name,
         cd_sales.cd_gender,
         inv_agg.total_on_hand
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
