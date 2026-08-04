WITH
    /* 1. Catalog Returns enriched */
    catalog AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cr.cr_refunded_cash,
            cr.cr_returned_time_sk,
            cr.cr_item_sk,
            cr.cr_reason_sk,
            cr.cr_ship_mode_sk,
            cr.cr_warehouse_sk,
            cr.cr_refunded_cdemo_sk,
            i.i_item_id,
            i.i_current_price,
            r.r_reason_desc,
            sm.sm_type,
            w.w_warehouse_name,
            t.t_hour
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        WHERE i.i_current_price > 75               -- predicate 1
          AND sm.sm_type = 'EXPRESS'               -- predicate 2
          AND t.t_hour BETWEEN 9 AND 19           -- predicate 3
    ),
    /* 2. Store Returns enriched */
    store AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_amt,
            sr.sr_return_quantity,
            sr.sr_return_time_sk,
            sr.sr_item_sk,
            sr.sr_reason_sk,
            sr.sr_cdemo_sk,
            i.i_item_id,
            i.i_current_price,
            r.r_reason_desc,
            t.t_hour
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE i.i_current_price < 120
          AND t.t_hour BETWEEN 10 AND 18
          AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
    ),
    /* 3. Web Sales enriched and linked to page & site */
    web AS (
        SELECT
            ws.ws_order_number,
            ws.ws_net_paid,
            ws.ws_quantity,
            ws.ws_sold_time_sk,
            ws.ws_item_sk,
            ws.ws_promo_sk,
            ws.ws_ship_mode_sk,
            ws.ws_warehouse_sk,
            ws.ws_bill_cdemo_sk,
            i.i_item_id,
            i.i_current_price,
            p.p_promo_name,
            sm.sm_type,
            w.w_warehouse_name,
            wp.wp_type,
            ws_site.web_name,
            t.t_hour
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        WHERE p.p_discount_active = 'Y'
          AND i.i_current_price BETWEEN 30 AND 250
          AND sm.sm_type = 'OVERNIGHT'
    ),
    /* 4. Inventory snapshot */
    inv AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_quantity_on_hand,
            i.i_item_id,
            i.i_current_price,
            w.w_warehouse_name
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE inv.inv_quantity_on_hand > 10
    ),
    /* 5. Demographics + income band */
    demo AS (
        SELECT
            cd.cd_demo_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            hd.hd_demo_sk,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM customer_demographics cd
        JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_lower_bound >= 60000
          AND cd.cd_marital_status = 'M'
    ),
    /* 6. Distinct list of items (used for DISTINCT requirement) */
    distinct_items AS (
        SELECT DISTINCT i_item_id FROM item
    ),
    /* 7. Order key sets for set operations */
    catalog_orders AS (SELECT cr_order_number AS order_id FROM catalog_returns),
    store_orders   AS (SELECT sr_ticket_number AS order_id FROM store_returns),
    web_orders     AS (SELECT ws_order_number   AS order_id FROM web_sales),
    catalog_minus_store AS (
        SELECT order_id FROM catalog_orders
        EXCEPT
        SELECT order_id FROM store_orders
    ),
    catalog_intersect_web AS (
        SELECT order_id FROM catalog_orders
        INTERSECT
        SELECT order_id FROM web_orders
    ),
    /* 8. Unnest monetary amounts from catalog returns */
    amounts AS (
        SELECT
            cr_order_number,
            amt
        FROM catalog c
        CROSS JOIN UNNEST(ARRAY[c.cr_return_amount, c.cr_refunded_cash]) AS t(amt)
    )
SELECT
    d.cd_gender,
    d.cd_marital_status,
    sm.sm_type,
    COUNT(DISTINCT c.cr_order_number)               AS catalog_order_cnt,
    COUNT(DISTINCT s.sr_ticket_number)               AS store_ticket_cnt,
    SUM(c.cr_return_amount)                         AS total_catalog_return,
    SUM(s.sr_return_amt)                            AS total_store_return,
    SUM(w.ws_net_paid)                              AS total_web_sales,
    AVG(i.i_current_price)                          AS avg_item_price,
    MIN(i.i_current_price)                          AS min_item_price,
    MAX(i.i_current_price)                          AS max_item_price,
    COUNT(DISTINCT a.amt)                           AS distinct_monetary_values,
    (SELECT COUNT(*) FROM catalog_minus_store)     AS catalog_orders_not_in_store,
    (SELECT COUNT(*) FROM catalog_intersect_web)   AS catalog_orders_in_web
FROM catalog c
JOIN store s          ON c.i_item_id = s.i_item_id
JOIN web   w          ON c.i_item_id = w.i_item_id
JOIN inv   i          ON c.i_item_id = i.i_item_id
JOIN demo  d          ON c.cr_refunded_cdemo_sk = d.cd_demo_sk
JOIN ship_mode sm    ON c.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN amounts a        ON c.cr_order_number = a.cr_order_number
WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
  AND d.cd_gender = 'F'
  AND i.i_current_price BETWEEN 80 AND 300
GROUP BY d.cd_gender, d.cd_marital_status, sm.sm_type
HAVING COUNT(DISTINCT c.cr_order_number) > 3
