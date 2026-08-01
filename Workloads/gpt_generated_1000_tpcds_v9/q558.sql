WITH combined_sales AS (
    SELECT
        d.d_year AS year,
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        p.p_promo_name AS promo_name,
        ws.web_name AS web_name,
        ss.ss_ext_sales_price AS store_sales_amt,
        0.0 AS catalog_sales_amt,
        COALESCE(sr.sr_return_amt, 0.0) AS return_amt,
        COALESCE(inv.inv_quantity_on_hand, 0) AS inv_on_hand,
        cc.cc_gmt_offset AS call_center_gmt_offset,
        r.r_reason_desc AS return_reason
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND s.s_state = 'CA'
        AND i.i_brand = 'Brand#12'
        AND cc.cc_gmt_offset = -8.00
        AND ws.web_country = 'United States'

    UNION ALL

    SELECT
        d.d_year AS year,
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        p.p_promo_name AS promo_name,
        ws.web_name AS web_name,
        0.0 AS store_sales_amt,
        cs.cs_ext_sales_price AS catalog_sales_amt,
        COALESCE(sr.sr_return_amt, 0.0) AS return_amt,
        COALESCE(inv.inv_quantity_on_hand, 0) AS inv_on_hand,
        cc.cc_gmt_offset AS call_center_gmt_offset,
        r.r_reason_desc AS return_reason
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND s.s_state = 'CA'
        AND i.i_brand = 'Brand#12'
        AND cc.cc_gmt_offset = -8.00
        AND ws.web_country = 'United States'
)
SELECT
    year,
    store_id,
    item_id,
    brand,
    promo_name,
    web_name,
    SUM(store_sales_amt) AS total_store_sales,
    SUM(catalog_sales_amt) AS total_catalog_sales,
    SUM(return_amt) AS total_returns,
    SUM(inv_on_hand) AS total_inventory_on_hand,
    AVG(store_sales_amt) AS avg_store_sales_per_group,
    (SELECT AVG(total_store_sales) FROM (
        SELECT year, SUM(store_sales_amt) AS total_store_sales
        FROM combined_sales
        GROUP BY year
    ) AS yearly_sales) AS avg_yearly_store_sales
FROM combined_sales
GROUP BY CUBE (year, store_id, item_id, brand, promo_name, web_name)
HAVING SUM(store_sales_amt) > 5000
ORDER BY year DESC, total_store_sales DESC
LIMIT 100
