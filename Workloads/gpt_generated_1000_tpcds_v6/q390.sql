WITH
    inventory_agg AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_date_sk,
            SUM(inv.inv_quantity_on_hand) AS total_qty
        FROM tpcds.inventory inv
        WHERE inv.inv_quantity_on_hand > 0
        GROUP BY inv.inv_item_sk, inv.inv_date_sk
    ),
    catalog_sales_detail AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_promo_sk,
            cs.cs_net_paid,
            cs.cs_ext_sales_price
        FROM tpcds.catalog_sales cs
        JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND cs.cs_quantity > 0
    ),
    store_sales_detail AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_sold_date_sk,
            ss.ss_ticket_number,
            ss.ss_cdemo_sk,
            ss.ss_promo_sk,
            ss.ss_net_paid,
            ss.ss_ext_sales_price
        FROM tpcds.store_sales ss
        JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND ss.ss_quantity > 0
    ),
    web_sales_detail AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_sold_date_sk,
            ws.ws_web_page_sk,
            ws.ws_web_site_sk,
            ws.ws_ship_mode_sk,
            ws.ws_bill_cdemo_sk,
            ws.ws_promo_sk,
            ws.ws_net_paid,
            ws.ws_ext_sales_price
        FROM tpcds.web_sales ws
        JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND ws.ws_quantity > 0
    ),
    store_returns_agg AS (
        SELECT
            ss.ss_item_sk AS item_sk,
            ss.ss_sold_date_sk AS date_sk,
            SUM(sr.sr_return_amt) AS total_return_amt
        FROM tpcds.store_returns sr
        JOIN tpcds.store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
    ),
    combined AS (
        SELECT
            i.i_item_id,
            i.i_category,
            i.i_current_price,
            i.i_wholesale_cost,
            d.d_year,
            d.d_month_seq,
            d.d_weekend,
            cd.cd_gender,
            cd.cd_purchase_estimate,
            p.p_discount_active,
            sm.sm_code,
            wp.wp_type,
            wsit.web_name,
            cp.cp_department,
            inv_agg.total_qty,
            csd.cs_net_paid AS catalog_net_paid,
            csd.cs_ext_sales_price AS catalog_sales_amt,
            ssd.ss_net_paid AS store_net_paid,
            ssd.ss_ext_sales_price AS store_sales_amt,
            wsd.ws_net_paid AS web_net_paid,
            wsd.ws_ext_sales_price AS web_sales_amt,
            rra.total_return_amt,
            COALESCE(p.p_discount_active, 'N') AS promo_active
        FROM tpcds.item i
        JOIN inventory_agg inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
        JOIN tpcds.date_dim d ON inv_agg.inv_date_sk = d.d_date_sk
        LEFT JOIN catalog_sales_detail csd ON i.i_item_sk = csd.cs_item_sk AND d.d_date_sk = csd.cs_sold_date_sk
        LEFT JOIN store_sales_detail ssd ON i.i_item_sk = ssd.ss_item_sk AND d.d_date_sk = ssd.ss_sold_date_sk
        LEFT JOIN web_sales_detail wsd ON i.i_item_sk = wsd.ws_item_sk AND d.d_date_sk = wsd.ws_sold_date_sk
        LEFT JOIN store_returns_agg rra ON i.i_item_sk = rra.item_sk AND d.d_date_sk = rra.date_sk
        LEFT JOIN catalog_page cp ON csd.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN promotion p ON csd.cs_promo_sk = p.p_promo_sk AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        LEFT JOIN ship_mode sm ON csd.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN customer_demographics cd ON csd.cs_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_page wp ON wsd.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site wsit ON wsd.ws_web_site_sk = wsit.web_site_sk
        WHERE i.i_current_price > 10
          AND i.i_wholesale_cost < 20
          AND d.d_month_seq BETWEEN 1200 AND 1300
          AND d.d_weekend = 'N'
          AND p.p_discount_active = 'Y'
          AND cd.cd_purchase_estimate > 5000
          AND sm.sm_code = 'AIR'
          AND wsit.web_country = 'United States'
    )
SELECT
    i_category,
    cd_gender,
    SUM(total_qty) AS sum_inventory_qty,
    SUM(catalog_net_paid) AS sum_catalog_net_paid,
    SUM(store_net_paid) AS sum_store_net_paid,
    SUM(web_net_paid) AS sum_web_net_paid,
    SUM(total_return_amt) AS sum_return_amt
FROM combined
GROUP BY ROLLUP (i_category, cd_gender)

UNION ALL

SELECT
    'ALL' AS i_category,
    'ALL' AS cd_gender,
    SUM(total_qty) AS sum_inventory_qty,
    SUM(catalog_net_paid) AS sum_catalog_net_paid,
    SUM(store_net_paid) AS sum_store_net_paid,
    SUM(web_net_paid) AS sum_web_net_paid,
    SUM(total_return_amt) AS sum_return_amt
FROM combined

ORDER BY i_category NULLS LAST, cd_gender NULLS LAST
LIMIT 100
