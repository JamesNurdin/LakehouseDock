/*
Goal: Analyze item‑level sales performance across the full TPC‑DS data model, linking catalog returns, sales, promotions, customers, stores, web activity and supporting dimensions. The query joins all 15 selected tables using only the permitted join keys, applies realistic filter predicates, computes aggregate sales metrics, includes a scalar subquery for average promotion cost, categorises sales volume with a CASE expression, and limits the result set.
*/
WITH base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        c.c_customer_id,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cc.cc_state,
        cc.cc_rec_start_date,
        i.i_brand,
        i.i_rec_start_date,
        cp.cp_department,
        p.p_cost,
        ws.ws_quantity,
        ws.ws_sold_date_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cp.cp_department = 'Sports'
      AND cr.cr_return_quantity > 2
      AND cr.cr_return_amount > 100.00
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_start_date >= DATE '2000-01-01'
)
SELECT
    b.i_item_id,
    b.i_product_name,
    b.c_customer_id,
    SUM(b.cs_ext_sales_price) AS total_sales,
    AVG(b.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT b.cs_order_number) AS order_cnt,
    MIN(b.cs_sold_date_sk) AS first_sold_date_sk,
    MAX(b.cs_sold_date_sk) AS last_sold_date_sk,
    (SELECT AVG(p2.p_cost)
       FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk) AS avg_promo_cost,
    CASE WHEN SUM(b.cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
FROM base b
JOIN item i ON b.i_item_id = i.i_item_id -- re‑join to expose i_item_sk for the scalar subquery
GROUP BY
    b.i_item_id,
    b.i_product_name,
    b.c_customer_id,
    i.i_item_sk
ORDER BY total_sales DESC
LIMIT 100
