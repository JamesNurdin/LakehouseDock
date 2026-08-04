WITH catalog_sales_enriched AS (
    SELECT
        cs.*,
        ARRAY[cs_quantity, cs_quantity + 1] AS qty_array
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
        SELECT i_item_sk FROM item WHERE i_color = 'Red'
    )
)
SELECT
    d_sold.d_year,
    i.i_category,
    cc.cc_state,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs_enriched.cs_order_number) AS orders,
    SUM(cs_enriched.cs_net_paid) AS total_net_paid,
    AVG(ss.ss_net_paid) AS avg_store_net_paid,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(wr.wr_return_amt) AS max_web_return_amt,
    SUM(qty_val) AS total_qty_expanded
FROM catalog_sales_enriched cs_enriched
JOIN date_dim d_sold
    ON cs_enriched.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON cs_enriched.cs_item_sk = i.i_item_sk
JOIN customer c
    ON cs_enriched.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON cs_enriched.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON cs_enriched.cs_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cs_enriched.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_enriched.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs_enriched.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs_enriched.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
    ON cs_enriched.cs_order_number = cr.cr_order_number
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_wp_create.d_date_sk
LEFT JOIN UNNEST(cs_enriched.qty_array) AS t(qty_val) ON TRUE
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND cs_enriched.cs_quantity >= 10
  AND hd.hd_buy_potential = '1001-5000'
GROUP BY
    d_sold.d_year,
    i.i_category,
    cc.cc_state,
    hd.hd_buy_potential
ORDER BY total_net_paid DESC
LIMIT 100
