WITH filtered_date AS (
    SELECT *
    FROM date_dim d
    WHERE d.d_year = 2002
      AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
)
SELECT
    d.d_year,
    i_ws.i_category,
    s.s_state,
    p.p_channel_tv,
    ib.ib_lower_bound,
    SUM(wsales.ws_net_paid_inc_ship_tax) AS total_net_sales,
    SUM(sret.sr_net_loss) AS total_net_loss,
    AVG(wsales.ws_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT i_ws.i_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages,
    CASE
        WHEN SUM(wsales.ws_net_paid_inc_ship_tax) > 100000 THEN 'High'
        ELSE 'Low'
    END AS sales_volume_category
FROM filtered_date d
JOIN store_returns sret
    ON sret.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_store_sk = sret.sr_store_sk
JOIN customer_address ca
    ON ca.ca_address_sk = sret.sr_addr_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = sret.sr_hdemo_sk
JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN item i_sret
    ON i_sret.i_item_sk = sret.sr_item_sk
JOIN web_sales wsales
    ON wsales.ws_sold_date_sk = d.d_date_sk
JOIN item i_ws
    ON i_ws.i_item_sk = wsales.ws_item_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i_ws.i_item_sk
JOIN warehouse w
    ON w.w_warehouse_sk = inv.inv_warehouse_sk
   AND w.w_warehouse_sk = wsales.ws_warehouse_sk
JOIN promotion p
    ON p.p_promo_sk = wsales.ws_promo_sk
   AND p.p_item_sk = i_ws.i_item_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wsales.ws_web_page_sk
JOIN web_site ws
    ON ws.web_site_sk = wsales.ws_web_site_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
WHERE
    i_ws.i_brand = 'Brand#12'
    AND ib.ib_lower_bound >= 50000
    AND p.p_channel_tv = 'N'
    AND s.s_state = 'CA'
    AND wsales.ws_quantity > 0
GROUP BY
    d.d_year,
    i_ws.i_category,
    s.s_state,
    p.p_channel_tv,
    ib.ib_lower_bound
ORDER BY
    total_net_sales DESC,
    d.d_year ASC
