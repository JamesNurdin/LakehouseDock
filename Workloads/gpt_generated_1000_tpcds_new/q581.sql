WITH
    -- Aggregate catalog sales with required dimensions and filters
    catalog_sales_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_time_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_addr_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            cs.cs_promo_sk,
            cs.cs_order_number,
            SUM(cs.cs_net_paid)                AS cat_sales,
            COUNT(*)                           AS cat_cnt,
            MAX(cs.cs_net_paid)                AS cat_max,
            MIN(cs.cs_net_paid)                AS cat_min,
            SUM(cs.cs_quantity)                AS total_quantity,
            CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'HIGH' ELSE 'LOW' END AS qty_category
        FROM
            catalog_sales cs
            JOIN time_dim td               ON cs.cs_sold_time_sk = td.t_time_sk
            JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
            JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
            JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
            JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
            JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
            JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
            JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
            JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
            JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
            JOIN catalog_page cp            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE
            td.t_hour = 9                     -- selective filter 1
            AND sm.sm_carrier = 'TBS'          -- selective filter 2
            AND i.i_brand = 'Brand#12'         -- selective filter 3
        GROUP BY
            cs.cs_item_sk,
            cs.cs_sold_time_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_addr_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            cs.cs_promo_sk,
            cs.cs_order_number
    ),
    -- Aggregate web sales with matching dimensions and filters
    web_sales_agg AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_sold_time_sk,
            ws.ws_web_page_sk,
            ws.ws_order_number,
            SUM(ws.ws_net_paid) AS web_sales,
            COUNT(*)            AS web_cnt
        FROM
            web_sales ws
            JOIN time_dim td          ON ws.ws_sold_time_sk = td.t_time_sk
            JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
            JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
            JOIN item i               ON ws.ws_item_sk = i.i_item_sk
            JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE
            td.t_hour = 9
            AND sm.sm_carrier = 'TBS'
        GROUP BY
            ws.ws_item_sk,
            ws.ws_sold_time_sk,
            ws.ws_web_page_sk,
            ws.ws_order_number
    ),
    -- Intersection of items that appear in both sales channels
    intersect_items AS (
        SELECT cs_item_sk AS item_sk FROM catalog_sales_agg
        INTERSECT
        SELECT ws_item_sk FROM web_sales_agg
    ),
    -- Full outer join between catalog returns and catalog sales (valid join rule)
    returns_full_outer AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cs.cs_net_paid AS sales_net_paid
        FROM
            catalog_returns cr
            FULL OUTER JOIN catalog_sales cs
                ON cr.cr_order_number = cs.cs_order_number
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    ca.ca_city,
    cc.cc_name,
    p.p_promo_name,
    sm.sm_carrier,
    td.t_hour,
    cs_agg.cat_sales,
    ws_agg.web_sales,
    (cs_agg.cat_sales + ws_agg.web_sales)                         AS total_sales,
    cs_agg.qty_category,
    COALESCE(rfo.cr_return_amount, 0)                           AS catalog_return_amount,
    (
        SELECT COALESCE(SUM(wr.wr_return_amt), 0)
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
    )                                                            AS web_return_total,
    (
        SELECT MAX(ib.ib_upper_bound)
        FROM income_band ib
    )                                                            AS max_income_upper_bound,
    CASE
        WHEN cs_agg.cat_sales > ws_agg.web_sales THEN 'CATALOG_LEADS'
        ELSE 'WEB_LEADS'
    END                                                          AS leading_channel
FROM
    intersect_items ii
    JOIN catalog_sales_agg cs_agg ON ii.item_sk = cs_agg.cs_item_sk
    JOIN web_sales_agg ws_agg   ON ii.item_sk = ws_agg.ws_item_sk
    JOIN item i                  ON ii.item_sk = i.i_item_sk
    JOIN customer_address ca    ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc         ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p            ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm           ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp        ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td            ON cs_agg.cs_sold_time_sk = td.t_time_sk
    JOIN customer c             ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp            ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN returns_full_outer rfo ON cs_agg.cs_order_number = rfo.cr_order_number
WHERE
    NOT EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
    )
    AND NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
    )
ORDER BY
    total_sales DESC,
    i.i_item_id
LIMIT 100
