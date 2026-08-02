WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 100
    )
)
SELECT
    s.s_store_id,
    d.d_year,
    p.p_promo_name,
    CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Medium' END AS income_band_category,
    COUNT(DISTINCT fs.cs_order_number) AS orders,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_net_profit) AS avg_net_profit,
    SUM(CASE WHEN fs.cs_quantity > 5 THEN fs.cs_ext_sales_price ELSE 0 END) AS high_qty_sales,
    MIN(fs.cs_sold_date_sk) AS min_sold_date_key,
    MAX(fs.cs_sold_date_sk) AS max_sold_date_key
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN filtered_sales fs ON fs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = fs.cs_order_number
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 100000
    AND hd.hd_buy_potential = '>10000'
GROUP BY
    s.s_store_id,
    d.d_year,
    p.p_promo_name,
    CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Medium' END
ORDER BY total_net_paid DESC
LIMIT 100
