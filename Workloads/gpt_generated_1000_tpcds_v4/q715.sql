WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        i.i_item_id,
        i.i_category,
        i.i_color,
        c.c_customer_id,
        w.w_warehouse_name,
        p.p_promo_name,
        cc.cc_country,
        cc.cc_rec_start_date,
        cc.cc_gmt_offset,
        cp.cp_type,
        cd.cd_gender,
        cd.cd_education_status,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_country = 'United States'
      AND i.i_color IN ('Red', 'Blue')
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'Electronics'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_gmt_offset > 0
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
    GROUP BY
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        i.i_item_id,
        i.i_category,
        i.i_color,
        c.c_customer_id,
        w.w_warehouse_name,
        p.p_promo_name,
        cc.cc_country,
        cc.cc_rec_start_date,
        cc.cc_gmt_offset,
        cp.cp_type,
        cd.cd_gender,
        cd.cd_education_status
),
joined_all AS (
    SELECT
        bs.cs_order_number,
        bs.i_item_id,
        bs.i_category,
        bs.c_customer_id,
        bs.w_warehouse_name,
        bs.p_promo_name,
        bs.total_net_paid,
        bs.sales_cnt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        wp.wp_url,
        ws.ws_quantity,
        ws.ws_net_paid,
        s.s_store_name,
        r.r_reason_desc,
        we.web_name
    FROM base_sales bs
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = bs.cs_item_sk
       AND sr.sr_customer_sk = bs.cs_bill_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = bs.cs_item_sk
       AND cr.cr_refunded_customer_sk = bs.cs_bill_customer_sk
       AND cr.cr_order_number = bs.cs_order_number
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = bs.cs_item_sk
       AND inv.inv_warehouse_sk = bs.cs_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = bs.cs_item_sk
       AND ws.ws_bill_customer_sk = bs.cs_bill_customer_sk
       AND ws.ws_warehouse_sk = bs.cs_warehouse_sk
    LEFT JOIN web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN web_site we
        ON we.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, cr.cr_reason_sk)
),
category_stats AS (
    SELECT
        ja.i_category,
        SUM(ja.total_net_paid) AS cat_total_net,
        COUNT(DISTINCT ja.c_customer_id) AS unique_customers,
        AVG(ja.sales_cnt) AS avg_sales_cnt,
        SUM(COALESCE(ja.sr_return_quantity, 0)) AS total_store_returns,
        SUM(COALESCE(ja.cr_return_quantity, 0)) AS total_catalog_returns,
        SUM(COALESCE(ja.inv_quantity_on_hand, 0)) AS total_inventory,
        COUNT(DISTINCT ja.wp_url) AS distinct_pages
    FROM joined_all ja
    WHERE ja.sr_return_quantity IS NOT NULL
      AND ja.cr_return_quantity IS NOT NULL
      AND ja.inv_quantity_on_hand > 500
    GROUP BY ja.i_category
    HAVING SUM(ja.total_net_paid) > 10000
)
SELECT
    cs.i_category,
    cs.cat_total_net,
    cs.unique_customers,
    cs.avg_sales_cnt,
    cs.total_store_returns,
    cs.total_catalog_returns,
    cs.total_inventory,
    cs.distinct_pages,
    (SELECT MAX(cat_total_net) FROM category_stats) AS max_category_net,
    (SELECT COUNT(*) FROM category_stats WHERE cat_total_net > 20000) AS categories_above_20k
FROM category_stats cs
ORDER BY cs.cat_total_net DESC
LIMIT 10
