WITH all_data AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        cd.cd_credit_rating,
        ib.ib_upper_bound,
        s.s_state,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        p.p_discount_active,
        sm.sm_type,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        sr.sr_return_amt,
        cp.cp_department,
        wp.wp_type,
        webs.web_name
    FROM item i
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
    WHERE i.i_current_price > 100.00
      AND cd.cd_credit_rating = 'Good'
      AND ib.ib_upper_bound >= 150000
      AND s.s_state = 'CA'
),
brand_aggregates AS (
    SELECT
        i_brand,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        (SUM(cs_quantity) + SUM(ws_quantity) + SUM(ss_quantity)) AS total_quantity,
        CASE
            WHEN SUM(cs_ext_sales_price) > 50000 THEN 'High'
            WHEN SUM(cs_ext_sales_price) > 20000 THEN 'Medium'
            ELSE 'Low'
        END AS catalog_sales_category
    FROM all_data
    GROUP BY i_brand
),
high_category AS (
    SELECT
        i_brand,
        total_catalog_sales,
        total_web_sales,
        total_store_sales,
        total_quantity,
        catalog_sales_category
    FROM brand_aggregates
    WHERE catalog_sales_category = 'High'
),
low_category AS (
    SELECT
        i_brand,
        total_catalog_sales,
        total_web_sales,
        total_store_sales,
        total_quantity,
        catalog_sales_category
    FROM brand_aggregates
    WHERE catalog_sales_category <> 'High'
),
combined_brands AS (
    SELECT
        i_brand,
        total_catalog_sales,
        total_web_sales,
        total_store_sales,
        total_quantity,
        catalog_sales_category
    FROM high_category
    UNION ALL
    SELECT
        i_brand,
        total_catalog_sales,
        total_web_sales,
        total_store_sales,
        total_quantity,
        catalog_sales_category
    FROM low_category
)
SELECT
    i_brand,
    total_catalog_sales,
    total_web_sales,
    total_store_sales,
    total_quantity,
    catalog_sales_category,
    ROW_NUMBER() OVER (PARTITION BY catalog_sales_category ORDER BY total_catalog_sales DESC) AS sales_rank,
    (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) AS avg_catalog_sales_price
FROM combined_brands
ORDER BY total_catalog_sales DESC
LIMIT 100
