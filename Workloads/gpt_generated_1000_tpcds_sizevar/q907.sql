WITH
    -- Base fact table with needed dimensions
    store_fact AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_item_sk,
            ss.ss_store_sk,
            ss.ss_promo_sk,
            ss.ss_cdemo_sk,
            ss.ss_hdemo_sk,
            ss.ss_ticket_number,
            ss.ss_net_paid,
            ss.ss_ext_tax,
            ss.ss_wholesale_cost,
            ss.ss_sales_price,
            d.d_date_sk,
            d.d_year,
            t.t_time_sk,
            t.t_hour,
            i.i_item_sk,
            i.i_brand,
            i.i_category,
            s.s_store_sk,
            s.s_store_id,
            s.s_state,
            p.p_promo_sk,
            p.p_discount_active,
            cd.cd_demo_sk,
            hd.hd_demo_sk,
            hd.hd_income_band_sk
        FROM store_sales ss
        JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i       ON ss.ss_item_sk = i.i_item_sk
        JOIN store s      ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p  ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    )
SELECT
    s.s_store_id,
    d.d_year,
    i.i_brand,
    SUM(sf.ss_net_paid)               AS total_net_paid,
    AVG(sf.ss_ext_tax)                AS avg_tax,
    COUNT(DISTINCT sf.ss_ticket_number) AS distinct_orders,
    MIN(sf.ss_wholesale_cost)         AS min_wholesale_cost,
    MAX(sf.ss_sales_price)            AS max_sales_price,
    (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year_in_data
FROM store_fact sf
JOIN catalog_sales cs       ON cs.cs_sold_date_sk = sf.d_date_sk
                              AND cs.cs_item_sk      = sf.ss_item_sk
JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr     ON cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws           ON ws.ws_sold_date_sk = sf.d_date_sk
                              AND ws.ws_item_sk   = sf.ss_item_sk
JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inventory inv          ON inv.inv_item_sk = sf.ss_item_sk
                              AND inv.inv_date_sk = sf.d_date_sk
JOIN income_band ib         ON sf.hd_income_band_sk = ib.ib_income_band_sk
JOIN date_dim d             ON sf.d_date_sk = d.d_date_sk   -- reuse for grouping
JOIN time_dim t             ON sf.t_time_sk = t.t_time_sk   -- reuse for filtering
JOIN item i                 ON sf.i_item_sk = i.i_item_sk   -- reuse for grouping
JOIN store s                ON sf.s_store_sk = s.s_store_sk   -- reuse for grouping
JOIN promotion p            ON sf.p_promo_sk = p.p_promo_sk   -- reuse for filtering
WHERE
    d.d_year = 2001                                            -- predicate 1
    AND t.t_hour BETWEEN 9 AND 17                               -- predicate 2
    AND i.i_brand = 'Brand#12'                                   -- predicate 3
    AND s.s_state = 'CA'                                         -- predicate 4
    AND p.p_discount_active = 'Y'                               -- predicate 5
    -- Anti‑join: keep rows where no catalog return exists for the same order
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_quantity > 0
    )
    -- Keep rows whose order number appears in both catalog_sales and web_sales
    AND sf.ss_ticket_number IN (
        SELECT order_num FROM (
            SELECT cs_order_number AS order_num FROM catalog_sales
            INTERSECT
            SELECT ws_order_number FROM web_sales
        )
    )
    -- Keep rows for items that exist in inventory but not in any store_sales record
    AND sf.ss_item_sk IN (
        SELECT inv_item_sk FROM inventory
        EXCEPT
        SELECT ss_item_sk FROM store_sales
    )
GROUP BY
    s.s_store_id,
    d.d_year,
    i.i_brand
HAVING
    SUM(sf.ss_net_paid) > 10000
ORDER BY
    total_net_paid DESC
LIMIT 100
