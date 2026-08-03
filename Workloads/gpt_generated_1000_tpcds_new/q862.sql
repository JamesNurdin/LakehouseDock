WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_sk,
            d.d_year,
            ss.ss_promo_sk,
            SUM(ss.ss_net_profit) AS store_profit,
            COUNT(*) AS store_txn
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY ss.ss_item_sk, d.d_year, ss.ss_promo_sk
    ),
    intersect_items AS (
        SELECT sr_item_sk AS item_sk FROM store_returns
        INTERSECT
        SELECT wr_item_sk FROM web_returns
    ),
    warehouse_attrs AS (
        SELECT
            w.w_warehouse_sk,
            t.key   AS attr_name,
            t.value AS attr_value
        FROM warehouse w
        CROSS JOIN UNNEST(
            map(
                array['city', 'state'],
                array[w.w_city, w.w_state]
            )
        ) AS t(key, value)
    )
SELECT
    d.d_year,
    p.p_promo_name,
    i.i_brand,
    SUM(ssa.store_profit)                 AS total_store_profit,
    SUM(ws.ws_net_profit)                 AS total_web_profit,
    COUNT(DISTINCT i.i_item_id)           AS distinct_items,
    COUNT(DISTINCT w.w_warehouse_id)      AS distinct_warehouses,
    MIN(d.d_date)                         AS first_sale_date,
    MAX(d.d_date)                         AS last_sale_date,
    COUNT(DISTINCT wa.attr_name)          AS distinct_warehouse_attrs
FROM intersect_items it
JOIN store_sales_agg ssa ON it.item_sk = ssa.ss_item_sk
JOIN web_sales ws      ON it.item_sk = ws.ws_item_sk
JOIN date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promotion p       ON ws.ws_promo_sk = p.p_promo_sk
JOIN item i            ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w       ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN warehouse_attrs wa ON w.w_warehouse_sk = wa.w_warehouse_sk
JOIN web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we       ON ws.ws_web_site_sk = we.web_site_sk
JOIN time_dim td       ON ws.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store_returns sr   ON sr.sr_item_sk = i.i_item_sk
JOIN web_returns wr    ON wr.wr_item_sk = i.i_item_sk
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND sm.sm_carrier = 'FEDEX'
    AND w.w_state = 'CA'
    AND we.web_country = 'United States'
    AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 0
    )
GROUP BY
    d.d_year,
    p.p_promo_name,
    i.i_brand
HAVING
    SUM(ssa.store_profit) > 10000
ORDER BY
    total_store_profit DESC,
    d.d_year
