WITH base_sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        w.w_warehouse_name,
        sm.sm_type,
        p.p_promo_name,
        cs.cs_order_number,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        cr.cr_return_amount AS catalog_return_amount,
        ws.ws_order_number,
        ws.ws_ext_sales_price AS web_sales_amount,
        wr.wr_return_amt AS web_return_amount,
        inv.inv_quantity_on_hand,
        t.t_hour,
        c.c_birth_month,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ws.ws_web_page_sk
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
        AND w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
           AND i.i_item_sk = wr.wr_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        i.i_category = 'Sports'
        AND c.c_birth_month BETWEEN 5 AND 8
        AND ca.ca_state = 'TX'
        AND t.t_hour BETWEEN 8 AND 17
        AND p.p_discount_active = 'Y'
),
store_ret_agg AS (
    SELECT
        i.i_item_id,
        s.s_store_name,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt > 0
    GROUP BY i.i_item_id, s.s_store_name
)
SELECT
    bs.i_category,
    bs.w_warehouse_name,
    bs.sm_type,
    SUM(bs.catalog_sales_amount) AS total_catalog_sales,
    SUM(bs.catalog_return_amount) AS total_catalog_returns,
    SUM(bs.web_sales_amount) AS total_web_sales,
    SUM(bs.web_return_amount) AS total_web_returns,
    COALESCE(SUM(st.store_return_amount), 0) AS total_store_returns,
    AVG(bs.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT bs.cs_order_number) AS num_orders
FROM base_sales bs
LEFT JOIN store_ret_agg st
    ON bs.i_item_id = st.i_item_id
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_web_page_sk = bs.ws_web_page_sk
      AND wp2.wp_link_count > 10
)
GROUP BY
    bs.i_category,
    bs.w_warehouse_name,
    bs.sm_type
HAVING
    SUM(bs.catalog_sales_amount) > 10000
    AND SUM(bs.web_sales_amount) > 5000
ORDER BY total_catalog_sales DESC
LIMIT 100
