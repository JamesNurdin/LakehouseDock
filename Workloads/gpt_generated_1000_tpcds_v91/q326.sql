WITH item_metrics AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_txn_cnt,
        (SELECT MAX(p.p_cost) FROM promotion p WHERE p.p_item_sk = i.i_item_sk) AS max_promo_cost,
        inv.inv_quantity_on_hand,
        c_bill.c_customer_id AS billing_customer_id,
        c_ship.c_customer_id AS shipping_customer_id,
        p_sales.p_promo_name AS sales_promo_name,
        p_catalog.p_promo_name AS catalog_promo_name,
        r.r_reason_desc,
        cp.cp_department,
        wp.wp_url
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN promotion p_sales ON ss.ss_promo_sk = p_sales.p_promo_sk
    LEFT JOIN promotion p_catalog ON cs.cs_promo_sk = p_catalog.p_promo_sk
    LEFT JOIN customer c_bill ON ss.ss_customer_sk = c_bill.c_customer_sk
    LEFT JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        inv.inv_quantity_on_hand,
        c_bill.c_customer_id,
        c_ship.c_customer_id,
        p_sales.p_promo_name,
        p_catalog.p_promo_name,
        r.r_reason_desc,
        cp.cp_department,
        wp.wp_url
),
price_tiers AS (
    SELECT 'Low' AS tier, 0 AS min_price, 100 AS max_price
    UNION ALL SELECT 'Medium', 101, 500
    UNION ALL SELECT 'High', 501, 10000
)
SELECT
    im.i_item_sk,
    im.i_product_name,
    im.i_brand,
    im.store_sales_total,
    im.catalog_sales_total,
    im.web_sales_total,
    (im.store_sales_total + im.catalog_sales_total + im.web_sales_total) AS total_sales,
    im.max_promo_cost,
    im.inv_quantity_on_hand,
    im.billing_customer_id,
    im.shipping_customer_id,
    im.sales_promo_name,
    im.catalog_promo_name,
    im.r_reason_desc,
    im.cp_department,
    im.wp_url,
    pt.tier,
    SUM(im.store_sales_total + im.catalog_sales_total + im.web_sales_total) OVER (PARTITION BY pt.tier) AS tier_sales_total,
    RANK() OVER (ORDER BY (im.store_sales_total + im.catalog_sales_total + im.web_sales_total) DESC) AS sales_rank
FROM item_metrics im
CROSS JOIN price_tiers pt
WHERE (im.store_sales_total + im.catalog_sales_total + im.web_sales_total) BETWEEN pt.min_price AND pt.max_price
ORDER BY total_sales DESC, im.i_item_sk
LIMIT 100
