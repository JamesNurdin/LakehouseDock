WITH
joined_all AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_brand,
        i.i_category,
        p.p_channel_tv,
        s.s_state,
        w.w_state,
        cc.cc_name,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cs.cs_quantity,
        cs.cs_net_profit,
        ws.ws_quantity,
        ws.ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        r.r_reason_desc,
        wp.wp_type,
        web_site.web_name,
        inv.inv_quantity_on_hand,
        (SELECT MAX(d_year) FROM date_dim) AS max_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN reason r
        ON (cr.cr_reason_sk = r.r_reason_sk OR wr.wr_reason_sk = r.r_reason_sk)
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    LEFT JOIN warehouse w
        ON (cs.cs_warehouse_sk = w.w_warehouse_sk OR ws.ws_warehouse_sk = w.w_warehouse_sk)
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1998
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#45'
      AND p.p_channel_tv = 'Y'
      AND s.s_state = 'CA'
      AND w.w_gmt_offset > -5.0
),
full_cc_cr AS (
    SELECT *
    FROM call_center cc
    FULL OUTER JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    WHERE cc.cc_name IS NOT NULL OR cr.cr_return_quantity IS NOT NULL
),
inventory_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
agg1 AS (
    SELECT
        d_year,
        i_brand,
        SUM(ss_quantity) AS total_ss_qty,
        SUM(ss_net_paid) AS total_ss_paid,
        SUM(cs_quantity) AS total_cs_qty,
        SUM(ws_quantity) AS total_ws_qty,
        AVG(inv_quantity_on_hand) AS avg_inv_qty,
        MAX(max_year) AS max_year
    FROM joined_all
    GROUP BY d_year, i_brand
    HAVING SUM(ss_net_paid) > 100000
),
agg2 AS (
    SELECT
        d.d_year,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_inv_qty,
        NULL AS total_ss_paid,
        NULL AS total_cs_qty,
        NULL AS total_ws_qty,
        NULL AS avg_inv_qty,
        (SELECT MAX(d_year) FROM date_dim) AS max_year
    FROM inventory_sample inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand) > 500
)
SELECT
    d_year,
    i_brand,
    total_ss_qty,
    total_ss_paid,
    total_cs_qty,
    total_ws_qty,
    avg_inv_qty,
    max_year
FROM agg1
UNION DISTINCT
SELECT
    d_year,
    i_brand,
    total_inv_qty AS total_ss_qty,
    total_ss_paid,
    total_cs_qty,
    total_ws_qty,
    avg_inv_qty,
    max_year
FROM agg2
ORDER BY d_year DESC, i_brand ASC
OFFSET 0 LIMIT 100
