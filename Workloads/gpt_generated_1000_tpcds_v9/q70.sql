WITH intersect_orders AS (
    SELECT cs_int.cs_order_number AS order_number
    FROM catalog_sales cs_int
    WHERE cs_int.cs_net_paid > 2000
    INTERSECT
    SELECT ws_int.ws_order_number AS order_number
    FROM web_sales ws_int
    WHERE ws_int.ws_net_paid > 2000
)
SELECT
    d.d_year,
    i.i_category,
    st.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(ws.ws_net_paid_inc_ship_tax) AS avg_web_total_paid,
    MIN(cs.cs_net_paid) AS min_catalog_sale,
    MAX(cs.cs_net_paid) AS max_catalog_sale
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN warehouse wh
    ON cs.cs_warehouse_sk = wh.w_warehouse_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer cu
    ON cs.cs_bill_customer_sk = cu.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
JOIN store st
    ON ss.ss_store_sk = st.s_store_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN catalog_returns rp
    ON rp.cr_order_number = cs.cs_order_number
   AND rp.cr_item_sk = i.i_item_sk
   AND rp.cr_warehouse_sk = wh.w_warehouse_sk
WHERE
    d.d_date >= DATE '2001-01-01'
    AND d.d_date < DATE '2002-01-01'
    AND i.i_category = 'Women'
    AND p_cs.p_discount_active = 'Y'
    AND cs.cs_net_paid > 1000
    AND ws.ws_net_paid_inc_ship_tax BETWEEN 1000 AND 5000
    AND st.s_state = 'CA'
    AND cc.cc_country = 'United States'
    AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
    AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          AND wp.wp_type = 'content'
    )
GROUP BY ROLLUP (d.d_year, i.i_category, st.s_state)
ORDER BY d.d_year ASC, i.i_category ASC, st.s_state ASC
LIMIT 100
