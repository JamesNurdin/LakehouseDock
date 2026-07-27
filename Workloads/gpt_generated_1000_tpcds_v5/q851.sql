WITH base AS (
    SELECT
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ca.ca_state,
        ca.ca_zip,
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_color,
        i.i_item_sk,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        wp.wp_max_ad_count
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_zip LIKE '9____'
      AND d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND wp.wp_max_ad_count >= 2
)
SELECT
    i_brand,
    i_color,
    CASE WHEN cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS order_type,
    d_month_seq,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(cs_net_profit + ws_net_profit) AS total_profit,
    COUNT(*) AS transaction_cnt,
    MIN(cs_ext_sales_price) AS min_catalog_price,
    MAX(ws_ext_sales_price) AS max_web_price,
    AVG(
        (SELECT AVG(inv_sub.inv_quantity_on_hand)
         FROM inventory inv_sub
         WHERE inv_sub.inv_item_sk = base.i_item_sk)
    ) AS avg_inventory_qty
FROM base
GROUP BY
    i_brand,
    i_color,
    CASE WHEN cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END,
    d_month_seq
HAVING SUM(cs_net_profit + ws_net_profit) > 10000
   AND COUNT(*) > 100
ORDER BY d_month_seq, total_profit DESC
