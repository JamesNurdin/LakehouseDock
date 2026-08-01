WITH aggregated_sales AS (
    SELECT
        t.t_hour AS t_hour,
        t.t_am_pm AS t_am_pm,
        s.s_store_name AS s_store_name,
        p_ss.p_promo_name AS p_promo_name,
        cc.cc_name AS cc_name,
        r.r_reason_desc AS r_reason_desc,
        ws.ws_order_number AS ws_order_number,
        SUM(ss.ss_net_paid) AS sum_store_sales_net_paid,
        SUM(cs.cs_net_paid_inc_tax) AS sum_catalog_sales_net_paid_inc_tax,
        SUM(ws.ws_net_paid) AS sum_web_sales_net_paid,
        SUM(cr.cr_net_loss) AS sum_catalog_returns_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_store_sales_tickets,
        SUM(CASE WHEN p_ss.p_discount_active = 'Y' THEN ss.ss_net_paid ELSE 0 END) AS sum_discounted_store_sales,
        SUM(CASE WHEN cc.cc_class = 'A' THEN cs.cs_net_paid_inc_tax ELSE 0 END) AS sum_class_A_catalog_sales
    FROM
        time_dim t
        JOIN (SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)) ss
            ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p_ss
            ON ss.ss_promo_sk = p_ss.p_promo_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p_cs
            ON cs.cs_promo_sk = p_cs.p_promo_sk
        JOIN catalog_returns cr
            ON cr.cr_returned_time_sk = t.t_time_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN promotion p_ws
            ON ws.ws_promo_sk = p_ws.p_promo_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we
            ON ws.ws_web_site_sk = we.web_site_sk
    WHERE
        cc.cc_rec_start_date > DATE '2000-01-01'
        AND s.s_market_id IN (5,7)
        AND we.web_company_id = 3
        AND p_ss.p_promo_name LIKE '%Discount%'
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        GROUPING SETS (
            (t.t_hour, t.t_am_pm, s.s_store_name, p_ss.p_promo_name, cc.cc_name, r.r_reason_desc, ws.ws_order_number),
            (t.t_hour, t.t_am_pm, s.s_store_name, p_ss.p_promo_name, cc.cc_name, r.r_reason_desc),
            (t.t_hour, t.t_am_pm, s.s_store_name, p_ss.p_promo_name, cc.cc_name),
            (t.t_hour, t.t_am_pm, s.s_store_name),
            ()
        )
)
SELECT
    t_hour,
    t_am_pm,
    s_store_name,
    p_promo_name,
    cc_name,
    r_reason_desc,
    ws_order_number,
    sum_store_sales_net_paid,
    sum_catalog_sales_net_paid_inc_tax,
    sum_web_sales_net_paid,
    sum_catalog_returns_net_loss,
    cnt_store_sales_tickets,
    sum_discounted_store_sales,
    sum_class_A_catalog_sales
FROM aggregated_sales
WHERE sum_store_sales_net_paid > 1000
ORDER BY t_hour, s_store_name, p_promo_name
LIMIT 100
