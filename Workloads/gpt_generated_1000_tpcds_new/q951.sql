WITH
    cs AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cc.cc_name,
            cp.cp_department,
            i.i_category,
            p.p_promo_name,
            sm.sm_type,
            w.w_warehouse_name,
            td.t_hour,
            CASE WHEN cs.cs_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_category
        FROM (
            SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)
        ) cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
          AND cs.cs_quantity > 5
          AND w.w_gmt_offset >= -5.00
    ),
    ws AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_quantity,
            ws.ws_net_paid,
            i.i_category,
            p.p_promo_name,
            sm.sm_type,
            w.w_warehouse_name,
            td.t_hour,
            CASE WHEN ws.ws_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_category
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
          AND ws.ws_quantity > 5
          AND sm.sm_type = 'AIR'
    ),
    sr AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_returned_date_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            i.i_category,
            td.t_hour,
            CASE WHEN sr.sr_return_amt > 500 THEN 'Big' ELSE 'Small' END AS return_category
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450825
          AND sr.sr_return_quantity > 1
          AND i.i_current_price > 50
    ),
    union_cs_ws AS (
        SELECT
            cs_order_number      AS order_key,
            cs_sold_date_sk      AS sold_date_sk,
            cs_quantity,
            cs_net_paid,
            cc_name,
            cp_department,
            i_category,
            p_promo_name,
            sm_type,
            w_warehouse_name,
            t_hour,
            sales_category
        FROM cs
        UNION
        SELECT
            ws_order_number,
            ws_sold_date_sk,
            ws_quantity,
            ws_net_paid,
            NULL AS cc_name,
            NULL AS cp_department,
            i_category,
            p_promo_name,
            sm_type,
            w_warehouse_name,
            t_hour,
            sales_category
        FROM ws
    ),
    final_join AS (
        SELECT
            u.order_key,
            u.sold_date_sk,
            u.cs_quantity,
            u.cs_net_paid,
            u.cc_name,
            u.cp_department,
            u.i_category,
            u.p_promo_name,
            u.sm_type,
            u.w_warehouse_name,
            u.t_hour,
            u.sales_category,
            sr.sr_ticket_number,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.return_category
        FROM union_cs_ws u
        FULL OUTER JOIN sr
            ON u.i_category = sr.i_category
            AND u.t_hour = sr.t_hour
    )
SELECT
    order_key,
    sold_date_sk,
    cs_quantity,
    cs_net_paid,
    cc_name,
    cp_department,
    i_category,
    p_promo_name,
    sm_type,
    w_warehouse_name,
    t_hour,
    sales_category,
    sr_ticket_number,
    sr_return_quantity,
    sr_return_amt,
    return_category,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY cs_net_paid DESC NULLS LAST) AS rn_category,
    RANK() OVER (ORDER BY cs_net_paid DESC) AS overall_rank
FROM final_join
WHERE order_key NOT IN (
        SELECT ws_order_number FROM web_sales WHERE ws_sold_date_sk < 2450800
    )
  AND (sales_category = 'High' OR return_category = 'Big')
ORDER BY overall_rank
LIMIT 100
