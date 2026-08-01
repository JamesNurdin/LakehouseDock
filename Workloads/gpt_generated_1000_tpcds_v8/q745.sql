/*
Goal: Identify high‑value stores in California and high‑value web orders, combining store and web sales data, while demonstrating advanced SQL features such as FULL OUTER JOIN, EXCEPT, UNION DISTINCT, correlated subqueries, and EXISTS semi‑joins.
*/
WITH
/* Store‑side aggregation – joins store_sales to many dimension tables */
store_sales_data AS (
    SELECT
        s.s_store_id               AS store_id,
        s.s_store_sk               AS store_sk,
        ca.ca_state                AS state,
        ib.ib_upper_bound          AS income_upper,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*)                   AS sales_cnt,
        AVG(ss.ss_quantity)       AS avg_qty,
        (
            SELECT COUNT(*)
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
        )                         AS store_return_cnt
    FROM store_sales ss
    JOIN store s                     ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd  ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib              ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p                 ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr      ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r               ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td                ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ca.ca_state = 'CA'
      AND ib.ib_upper_bound >= 80000
      AND s.s_gmt_offset = -5.00
    GROUP BY s.s_store_id, s.s_store_sk, ca.ca_state, ib.ib_upper_bound
),

/* Web‑side aggregation – joins web_sales to its dimension tables */
web_sales_data AS (
    SELECT
        ws.ws_order_number          AS order_number,
        ws.ws_quantity              AS quantity,
        ws.ws_ext_sales_price       AS ext_sales_price,
        sm.sm_type                  AS ship_mode_type,
        w.w_warehouse_name          AS warehouse_name,
        wp.wp_url                   AS web_page_url,
        (
            SELECT AVG(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
        )                         AS avg_warehouse_sales
    FROM web_sales ws
    JOIN ship_mode sm               ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we                ON ws.ws_web_site_sk = we.web_site_sk
    JOIN promotion p                ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td                ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE w.w_state = 'CA'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
      AND sm.sm_type = 'AIR'
),

/* Full outer join of warehouse and inventory – keeps rows that exist only in one side */
warehouse_inventory AS (
    SELECT
        w.w_warehouse_id   AS warehouse_id,
        w.w_city           AS city,
        inv.inv_quantity_on_hand AS quantity_on_hand
    FROM warehouse w
    FULL OUTER JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE w.w_state = 'CA'
),

/* Stores that never had any sales – demonstrated with EXCEPT */
store_without_sales AS (
    SELECT s_store_id FROM store
    EXCEPT
    SELECT s.s_store_id FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
)
/* Combine store and web aggregates using UNION DISTINCT */
SELECT
    store_id,
    state,
    income_upper,
    total_sales,
    sales_cnt,
    avg_qty,
    store_return_cnt,
    NULL               AS order_number,
    NULL               AS quantity,
    NULL               AS ext_sales_price,
    NULL               AS ship_mode_type,
    NULL               AS warehouse_name,
    NULL               AS avg_warehouse_sales,
    NULL               AS web_page_url
FROM store_sales_data

UNION DISTINCT

SELECT
    NULL               AS store_id,
    NULL               AS state,
    NULL               AS income_upper,
    NULL               AS total_sales,
    NULL               AS sales_cnt,
    NULL               AS avg_qty,
    NULL               AS store_return_cnt,
    order_number,
    quantity,
    ext_sales_price,
    ship_mode_type,
    warehouse_name,
    avg_warehouse_sales,
    web_page_url
FROM web_sales_data

/* Filter the combined result with an EXISTS semi‑join on web_returns and reason */
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE wr.wr_order_number = order_number
      AND r2.r_reason_desc LIKE '%damaged%'
)
ORDER BY total_sales DESC NULLS LAST, ext_sales_price DESC NULLS LAST
LIMIT 100
