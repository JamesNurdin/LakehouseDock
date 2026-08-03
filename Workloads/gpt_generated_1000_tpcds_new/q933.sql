WITH joined_all AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_market_manager,
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cr.cr_returned_date_sk,
        cs.cs_sold_date_sk,
        ws.ws_sold_date_sk,
        sr.sr_returned_date_sk,
        wr.wr_returned_date_sk,
        p.p_promo_sk,
        r.r_reason_sk,
        sm.sm_ship_mode_sk,
        w.w_warehouse_sk,
        i.inv_date_sk,
        dd.d_date,
        td.t_time_sk,
        ws.ws_order_number,
        cs.cs_order_number,
        cr.cr_order_number,
        sr.sr_ticket_number,
        wr.wr_order_number,
        cs.cs_net_paid,
        ws.ws_net_paid,
        sr.sr_net_loss,
        cr.cr_net_loss
    FROM call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim dd
        ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = dd.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = dd.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = dd.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = dd.d_date_sk
    WHERE dd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND cc.cc_market_manager = 'James Mcdonald'
      AND p.p_promo_name LIKE '%discount%'
),
set1 AS (
    SELECT DISTINCT cs_order_number AS order_num
    FROM joined_all
    WHERE cs_net_paid > 1000
),
set2 AS (
    SELECT DISTINCT ws_order_number AS order_num
    FROM joined_all
    WHERE ws_net_paid > 500
),
union_set AS (
    SELECT order_num FROM set1
    UNION
    SELECT order_num FROM set2
),
intersect_set AS (
    SELECT order_num FROM set1
    INTERSECT
    SELECT order_num FROM set2
),
except_set AS (
    SELECT order_num FROM set1
    EXCEPT
    SELECT order_num FROM set2
),
final AS (
    SELECT
        u.order_num,
        CASE WHEN i.order_num IS NOT NULL THEN 1 ELSE 0 END AS in_intersect,
        CASE WHEN e.order_num IS NOT NULL THEN 1 ELSE 0 END AS in_except,
        ROW_NUMBER() OVER (ORDER BY u.order_num) AS row_num
    FROM union_set u
    LEFT JOIN intersect_set i ON u.order_num = i.order_num
    LEFT JOIN except_set e ON u.order_num = e.order_num
)
SELECT order_num,
       in_intersect,
       in_except,
       row_num
FROM final
ORDER BY row_num
LIMIT 100
