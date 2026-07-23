WITH agg_store_sales AS (
    SELECT ss_item_sk,
           SUM(ss_ext_sales_price) AS store_sales_total,
           SUM(ss_quantity) AS store_qty_total
    FROM store_sales
    WHERE ss_ext_tax > 10.0
    GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    p.p_discount_active,
    cs.cs_order_number,
    cs.cs_quantity AS cs_quantity,
    cs.cs_ext_sales_price AS cs_ext_sales_price,
    ws.ws_quantity AS ws_quantity,
    ws.ws_ext_sales_price AS ws_ext_sales_price,
    cr.cr_return_amount AS cr_return_amount,
    cc.cc_name AS call_center_name,
    ws_site.web_name AS website_name,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    agg.store_sales_total,
    agg.store_qty_total,
    (agg.store_sales_total + cs.cs_ext_sales_price + ws.ws_ext_sales_price - COALESCE(cr.cr_return_amount, 0)) AS total_revenue,
    RANK() OVER (ORDER BY (agg.store_sales_total + cs.cs_ext_sales_price + ws.ws_ext_sales_price - COALESCE(cr.cr_return_amount, 0)) DESC) AS revenue_rank,
    (SELECT COUNT(DISTINCT p2.p_promo_sk) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS promo_count
FROM agg_store_sales agg
JOIN item i ON agg.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE p.p_discount_active = 'Y'
  AND i.i_brand = 'BrandA'
  AND cs.cs_quantity > 5
  AND ws.ws_net_profit > 0
  AND cc.cc_division = 2
ORDER BY total_revenue DESC
LIMIT 100
