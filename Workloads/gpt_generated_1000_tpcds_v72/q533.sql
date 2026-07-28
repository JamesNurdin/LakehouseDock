WITH item_cte AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_category,
        i_brand,
        i_color,
        i_current_price
    FROM item
    WHERE i_category = 'Sports'
      AND i_brand = 'Brand#12'
      AND i_color = 'PURPLE'
),
sales_agg AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        i.i_item_id,
        s.s_store_name,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        p.p_promo_name,
        p.p_discount_active,
        ws.web_name,
        wp.wp_url,
        t.t_am_pm,
        r.r_reason_desc,
        SUM(cs.cs_net_paid)               AS catalog_net_paid,
        SUM(ss.ss_net_paid)               AS store_net_paid,
        COUNT(DISTINCT cr.cr_order_number) AS return_cnt
    FROM catalog_sales cs
    JOIN date_dim d            ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item_cte i            ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c            ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p           ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN time_dim t       ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN store_sales ss   ON ss.ss_item_sk = i.i_item_sk
                               AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s          ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r         ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv    ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_page wp      ON wp.wp_creation_date_sk = d.d_date_sk
                               AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002                                          -- predicate 1
      AND p.p_channel_event = 'N'                                 -- predicate 2
      AND cs.cs_quantity > 5                                      -- predicate 3
      AND ss.ss_quantity > 3                                      -- predicate 4
      AND t.t_am_pm = 'PM'                                        -- predicate 5
      AND wp.wp_type = 'Content'                                  -- predicate 6
      AND ws.web_class = 'Technology'                             -- predicate 7
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND s.s_state = 'CA'
    GROUP BY
        d.d_date,
        i.i_item_sk,
        i.i_item_id,
        s.s_store_name,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        p.p_promo_name,
        p.p_discount_active,
        ws.web_name,
        wp.wp_url,
        t.t_am_pm,
        r.r_reason_desc
)
SELECT
    d_date,
    i_item_id,
    s_store_name,
    cc_name,
    cp_department,
    sm_type,
    p_promo_name,
    CASE WHEN p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_status,
    catalog_net_paid + store_net_paid AS total_net_paid,
    return_cnt,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = sales_agg.i_item_sk) AS max_promo_cost,
    web_name,
    wp_url,
    t_am_pm,
    r_reason_desc,
    RANK() OVER (PARTITION BY d_date ORDER BY catalog_net_paid + store_net_paid DESC) AS store_day_rank
FROM sales_agg
ORDER BY d_date, store_day_rank
LIMIT 100
