/* Goal: Summarize net profit and sales metrics by year, promotion, item and other dimensions for catalog and web sales, applying filters, anti‑joins, semi‑joins, a scalar subquery, CASE logic, DISTINCT UNION and a FULL OUTER JOIN. */
WITH catalog_data AS (
    SELECT
        d_sold.d_year AS sale_year,
        p.p_promo_id,
        i.i_item_id,
        i.i_manufact,
        sm.sm_code,
        cc.cc_state AS state_or_site,
        cp.cp_department AS department_or_type,
        CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS quantity_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MIN(cs.cs_quantity) AS min_qty,
        MAX(cs.cs_quantity) AS max_qty
    FROM
        call_center cc
        FULL OUTER JOIN catalog_sales cs
            ON cc.cc_call_center_sk = cs.cs_call_center_sk
        INNER JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        INNER JOIN time_dim t_sold
            ON cs.cs_sold_time_sk = t_sold.t_time_sk
        INNER JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        INNER JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        INNER JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN date_dim d_cc_open
            ON cc.cc_open_date_sk = d_cc_open.d_date_sk
        LEFT JOIN date_dim d_cc_close
            ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
        LEFT JOIN date_dim d_cp_start
            ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        LEFT JOIN date_dim d_cp_end
            ON cp.cp_end_date_sk = d_cp_end.d_date_sk
        LEFT JOIN date_dim d_p_start
            ON p.p_start_date_sk = d_p_start.d_date_sk
        LEFT JOIN date_dim d_p_end
            ON p.p_end_date_sk = d_p_end.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND i.i_manufact = 'barcallyable'
        AND sm.sm_code = 'AIR'
        AND cc.cc_state = 'CA'
        AND cp.cp_department = 'Sports'
        AND cs.cs_quantity > 5
        AND p.p_discount_active = 'Y'
        AND cs.cs_sold_date_sk = (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_year = 2001
        )
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
              AND p2.p_discount_active = 'Y'
        )
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
        )
    GROUP BY
        d_sold.d_year,
        p.p_promo_id,
        i.i_item_id,
        i.i_manufact,
        sm.sm_code,
        cc.cc_state,
        cp.cp_department,
        CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END
),
web_data AS (
    SELECT
        d_ws_sold.d_year AS sale_year,
        p.p_promo_id,
        i.i_item_id,
        i.i_manufact,
        sm.sm_code,
        ws_site.web_state AS state_or_site,
        wp.wp_type AS department_or_type,
        CASE WHEN ws.ws_quantity > 10 THEN 'Large' ELSE 'Small' END AS quantity_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MIN(ws.ws_quantity) AS min_qty,
        MAX(ws.ws_quantity) AS max_qty
    FROM
        web_sales ws
        INNER JOIN date_dim d_ws_sold
            ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        INNER JOIN time_dim t_ws_sold
            ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        INNER JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN web_site ws_site
            ON ws.ws_web_site_sk = ws_site.web_site_sk
        INNER JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        INNER JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        INNER JOIN ship_mode sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN customer c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN date_dim d_ws_site_open
            ON ws_site.web_open_date_sk = d_ws_site_open.d_date_sk
        LEFT JOIN date_dim d_ws_site_close
            ON ws_site.web_close_date_sk = d_ws_site_close.d_date_sk
        LEFT JOIN date_dim d_wp_creation
            ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        LEFT JOIN date_dim d_wp_access
            ON wp.wp_access_date_sk = d_wp_access.d_date_sk
        LEFT JOIN date_dim d_p_start
            ON p.p_start_date_sk = d_p_start.d_date_sk
        LEFT JOIN date_dim d_p_end
            ON p.p_end_date_sk = d_p_end.d_date_sk
    WHERE
        d_ws_sold.d_year = 2001
        AND i.i_manufact = 'barcallyable'
        AND sm.sm_code = 'AIR'
        AND ws_site.web_state = 'CA'
        AND wp.wp_type = 'Sports'
        AND ws.ws_quantity > 5
        AND p.p_discount_active = 'Y'
        AND ws.ws_sold_date_sk = (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_year = 2001
        )
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
              AND p2.p_discount_active = 'Y'
        )
        AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
        )
    GROUP BY
        d_ws_sold.d_year,
        p.p_promo_id,
        i.i_item_id,
        i.i_manufact,
        sm.sm_code,
        ws_site.web_state,
        wp.wp_type,
        CASE WHEN ws.ws_quantity > 10 THEN 'Large' ELSE 'Small' END
)
SELECT
    sale_year,
    p_promo_id,
    i_item_id,
    i_manufact,
    sm_code,
    state_or_site,
    department_or_type,
    quantity_category,
    SUM(total_net_profit) AS total_net_profit,
    AVG(avg_sales_price) AS avg_sales_price,
    SUM(distinct_orders) AS total_orders,
    MIN(min_qty) AS min_qty,
    MAX(max_qty) AS max_qty
FROM (
    SELECT
        cd.sale_year,
        cd.p_promo_id,
        cd.i_item_id,
        cd.i_manufact,
        cd.sm_code,
        cd.state_or_site,
        cd.department_or_type,
        cd.quantity_category,
        cd.total_net_profit,
        cd.avg_sales_price,
        cd.distinct_orders,
        cd.min_qty,
        cd.max_qty
    FROM catalog_data cd
    UNION
    SELECT
        wd.sale_year,
        wd.p_promo_id,
        wd.i_item_id,
        wd.i_manufact,
        wd.sm_code,
        wd.state_or_site,
        wd.department_or_type,
        wd.quantity_category,
        wd.total_net_profit,
        wd.avg_sales_price,
        wd.distinct_orders,
        wd.min_qty,
        wd.max_qty
    FROM web_data wd
) AS combined
GROUP BY
    sale_year,
    p_promo_id,
    i_item_id,
    i_manufact,
    sm_code,
    state_or_site,
    department_or_type,
    quantity_category
ORDER BY total_net_profit DESC
LIMIT 100
