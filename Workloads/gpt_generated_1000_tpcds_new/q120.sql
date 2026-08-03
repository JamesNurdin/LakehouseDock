WITH
    -- Aggregate web_sales first (pre‑aggregation step)
    ws_agg AS (
        SELECT
            ws_order_number,
            ws_sold_time_sk,
            ws_ship_mode_sk,
            ws_warehouse_sk,
            ws_promo_sk,
            ws_web_site_sk,
            SUM(ws_ext_sales_price)       AS ws_total_sales,
            SUM(ws_net_profit)            AS ws_total_profit,
            SUM(ws_quantity)              AS ws_total_qty
        FROM web_sales
        WHERE ws_quantity > 0
        GROUP BY
            ws_order_number,
            ws_sold_time_sk,
            ws_ship_mode_sk,
            ws_warehouse_sk,
            ws_promo_sk,
            ws_web_site_sk
    ),
    -- Join all tables together (deep join, ≥9 join clauses)
    joined_base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_paid,
            cc.cc_name,
            cp.cp_department,
            sm1.sm_type                     AS ship_type_cs,
            w1.w_warehouse_name,
            p1.p_promo_name,
            p1.p_channel_tv                 AS promo_tv,
            p1.p_discount_active            AS promo_discount_active,
            td1.t_hour,
            ws_agg.ws_total_sales,
            ws_agg.ws_total_profit,
            ws_agg.ws_total_qty,
            ws_site.web_name                AS web_site_name,
            cr.cr_return_amount,
            sr.sr_return_amt,
            CASE WHEN p1.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
        FROM catalog_sales cs
        JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm1           ON cs.cs_ship_mode_sk   = sm1.sm_ship_mode_sk
        JOIN warehouse w1            ON cs.cs_warehouse_sk   = w1.w_warehouse_sk
        JOIN promotion p1            ON cs.cs_promo_sk       = p1.p_promo_sk
        JOIN time_dim td1            ON cs.cs_sold_time_sk   = td1.t_time_sk
        -- join the pre‑aggregated web_sales using the shared time dimension
        LEFT JOIN ws_agg             ON ws_agg.ws_sold_time_sk = td1.t_time_sk
        LEFT JOIN web_site ws_site   ON ws_agg.ws_web_site_sk  = ws_site.web_site_sk
        -- additional aliases for the same dimension tables
        LEFT JOIN ship_mode sm2       ON ws_agg.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        LEFT JOIN warehouse w2        ON ws_agg.ws_warehouse_sk = w2.w_warehouse_sk
        LEFT JOIN promotion p2        ON ws_agg.ws_promo_sk    = p2.p_promo_sk
        -- catalog returns (joined via order number and time)
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                   AND cr.cr_returned_time_sk = td1.t_time_sk
        -- store returns (joined only through the time dimension)
        LEFT JOIN store_returns sr   ON sr.sr_return_time_sk = td1.t_time_sk
    ),
    -- First slice: promotion TV channel = 'N'
    first_set AS (
        SELECT
            cc_name,
            cp_department,
            SUM(cs_quantity)            AS total_quantity,
            SUM(cs_net_paid)            AS total_net_paid,
            SUM(ws_total_sales)         AS total_ws_sales,
            SUM(ws_total_profit)        AS total_ws_profit,
            SUM(cr_return_amount)       AS total_return_amount,
            SUM(sr_return_amt)          AS total_store_return,
            SUM(promo_active_flag)      AS active_promo_cnt,
            ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(cs_net_paid) DESC) AS rn
        FROM joined_base
        WHERE promo_tv = 'N'
        GROUP BY cc_name, cp_department
    ),
    -- Second slice: promotion TV channel = 'Y'
    second_set AS (
        SELECT
            cc_name,
            cp_department,
            SUM(cs_quantity)            AS total_quantity,
            SUM(cs_net_paid)            AS total_net_paid,
            SUM(ws_total_sales)         AS total_ws_sales,
            SUM(ws_total_profit)        AS total_ws_profit,
            SUM(cr_return_amount)       AS total_return_amount,
            SUM(sr_return_amt)          AS total_store_return,
            SUM(promo_active_flag)      AS active_promo_cnt,
            ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(cs_net_paid) DESC) AS rn
        FROM joined_base
        WHERE promo_tv = 'Y'
        GROUP BY cc_name, cp_department
    )
SELECT *
FROM (
    SELECT * FROM first_set  WHERE rn <= 5
    UNION DISTINCT
    SELECT * FROM second_set WHERE rn <= 5
) final_result
ORDER BY cc_name, total_net_paid DESC
LIMIT 100
