WITH
    cs_agg AS (
        SELECT
            cs_item_sk,
            cs_sold_date_sk,
            SUM(cs_net_paid)    AS total_net_paid,
            SUM(cs_quantity)   AS total_qty
        FROM catalog_sales
        GROUP BY cs_item_sk, cs_sold_date_sk
    ),
    diff_orders AS (
        SELECT cs_order_number FROM catalog_sales
        EXCEPT
        SELECT ws_order_number FROM web_sales
    ),
    wp_sample AS (
        SELECT *
        FROM web_page
        TABLESAMPLE BERNOULLI (10)
    ),
    reason_small AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
        WHERE r_reason_id = 'AAAAAAAAABAAAAAA'
    ),
    dummy_set AS (
        SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
    )
SELECT *
FROM (
    SELECT
        s.s_store_name,
        s.s_state,
        d_sold.d_year,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        cs_agg.total_net_paid,
        cs_agg.total_qty,
        COUNT(DISTINCT cs_agg.cs_item_sk)                 AS distinct_items,
        MIN(d_sold.d_date)                                 AS first_sale_date,
        MAX(d_sold.d_date)                                 AS last_sale_date,
        (SELECT COUNT(*) FROM diff_orders)                AS diff_order_cnt,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY cs_agg.total_net_paid DESC) AS rn
    FROM cs_agg
    JOIN catalog_sales cs
        ON cs.cs_item_sk = cs_agg.cs_item_sk
       AND cs.cs_sold_date_sk = cs_agg.cs_sold_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_ws_open
        ON we.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON we.web_close_date_sk = d_ws_close.d_date_sk
    JOIN wp_sample wp_s
        ON wp.wp_web_page_sk = wp_s.wp_web_page_sk
    JOIN reason_small rs
        ON r.r_reason_sk = rs.r_reason_sk
    CROSS JOIN dummy_set ds
    WHERE d_sold.d_year = 2001
      AND t_sold.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY
        s.s_store_name,
        s.s_state,
        d_sold.d_year,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        cs_agg.total_net_paid,
        cs_agg.total_qty
    HAVING cs_agg.total_net_paid > 10000
) ranked
WHERE ranked.rn <= 3
ORDER BY ranked.total_net_paid DESC
LIMIT 100
