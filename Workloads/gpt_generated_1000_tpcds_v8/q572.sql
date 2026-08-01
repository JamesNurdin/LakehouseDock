WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_quantity,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_promo_sk,
        t.t_time,
        i.i_item_id,
        i.i_current_price,
        i.i_category,
        c.c_customer_id,
        cd.cd_gender,
        st.s_store_name,
        st.s_state,
        p.p_promo_name,
        p.p_discount_active,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        cs.cs_order_number,
        cp.cp_catalog_page_number,
        cc.cc_name,
        ws.ws_order_number,
        wp.wp_url,
        wr.wr_return_quantity,
        CASE WHEN ss.ss_net_paid_inc_tax > (
                SELECT avg(ss2.ss_net_paid_inc_tax)
                FROM store_sales ss2
            ) THEN 'High' ELSE 'Low' END AS payment_category,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_net_paid_inc_tax DESC) AS rn
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE ss.ss_net_paid_inc_tax > 500
      AND i.i_current_price BETWEEN 50 AND 200
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
      AND ss.ss_store_sk IN (
          SELECT s_store_sk FROM store WHERE s_state = 'CA'
          INTERSECT
          SELECT s_store_sk FROM store WHERE s_tax_percentage > 0.07
      )
)
SELECT
    c_customer_id,
    i_item_id,
    ss_net_paid_inc_tax,
    rn
FROM joined
WHERE rn = 1
UNION DISTINCT
SELECT
    c_customer_id,
    i_item_id,
    ss_net_paid_inc_tax,
    rn
FROM joined
WHERE payment_category = 'High' AND ss_quantity > 2
LIMIT 100
