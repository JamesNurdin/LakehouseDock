WITH sales_by_item_ship AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        sm.sm_ship_mode_id,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_sum,
        SUM(ws.ws_ext_sales_price) AS web_sales_sum,
        COUNT(*) AS txn_cnt,
        SUM(CASE WHEN cs.cs_ext_ship_cost > 50 THEN 1 ELSE 0 END) AS high_ship_cnt
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_street_type IN ('Circle', 'Lane')
      AND sm.sm_carrier = 'FEDEX'
      AND cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 1000
      AND ws.ws_ext_discount_amt < 500
      AND i.i_current_price BETWEEN 10 AND 1000
      AND inv.inv_quantity_on_hand > 0
      AND wsite.web_country = 'United States'
    GROUP BY i.i_item_id, i.i_product_name, sm.sm_ship_mode_id
)
SELECT
    i_item_id AS item_id,
    i_product_name AS product_name,
    AVG(catalog_sales_sum + web_sales_sum) AS avg_total_sales,
    SUM(high_ship_cnt) AS total_high_ship_cnt
FROM sales_by_item_ship
GROUP BY i_item_id, i_product_name
HAVING AVG(catalog_sales_sum + web_sales_sum) > 2000
   AND SUM(high_ship_cnt) > 10
ORDER BY avg_total_sales DESC
LIMIT 10
