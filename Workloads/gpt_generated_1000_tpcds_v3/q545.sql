WITH ws_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_web_site_sk,
        ws_promo_sk,
        ws_web_page_sk,
        ws_bill_customer_sk,
        ws_warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk,
        ws_web_site_sk,
        ws_promo_sk,
        ws_web_page_sk,
        ws_bill_customer_sk,
        ws_warehouse_sk
),
sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM store_returns
    GROUP BY
        sr_returned_date_sk,
        sr_item_sk,
        sr_reason_sk
),
cr_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_cat_return_amount,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns
    GROUP BY
        cr_returned_date_sk,
        cr_item_sk,
        cr_reason_sk
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    cc.cc_name AS call_center_name,
    cp.cp_type AS catalog_page_type,
    p.p_promo_name,
    ws_site.web_name AS web_site_name,
    wp.wp_url,
    w.w_warehouse_name,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city AS customer_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    r_sr.r_reason_desc AS store_return_reason,
    r_cr.r_reason_desc AS catalog_return_reason,
    ws_agg.total_sales,
    ws_agg.total_profit,
    sr_agg.total_return_amount,
    cr_agg.total_cat_return_amount,
    ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY ws_agg.total_profit DESC) AS profit_rank
FROM date_dim d
LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN ws_agg
    ON ws_agg.ws_sold_date_sk = d.d_date_sk
LEFT JOIN item i
    ON i.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN promotion p
    ON p.p_promo_sk = ws_agg.ws_promo_sk
LEFT JOIN web_site ws_site
    ON ws_site.web_site_sk = ws_agg.ws_web_site_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = ws_agg.ws_web_page_sk
LEFT JOIN warehouse w
    ON w.w_warehouse_sk = ws_agg.ws_warehouse_sk
LEFT JOIN customer c
    ON c.c_customer_sk = ws_agg.ws_bill_customer_sk
LEFT JOIN customer_address ca
    ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN household_demographics hd
    ON hd.hd_demo_sk = c.c_current_hdemo_sk
LEFT JOIN sr_agg
    ON sr_agg.sr_returned_date_sk = d.d_date_sk
    AND sr_agg.sr_item_sk = i.i_item_sk
LEFT JOIN reason r_sr
    ON r_sr.r_reason_sk = sr_agg.sr_reason_sk
LEFT JOIN cr_agg
    ON cr_agg.cr_returned_date_sk = d.d_date_sk
    AND cr_agg.cr_item_sk = i.i_item_sk
LEFT JOIN reason r_cr
    ON r_cr.r_reason_sk = cr_agg.cr_reason_sk
WHERE
    d.d_year = 2001
    AND i.i_category = 'Sports'
    AND cc.cc_state = 'CA'
    AND p.p_discount_active = 'Y'
ORDER BY profit_rank ASC, d.d_date DESC, ws_agg.total_profit DESC
LIMIT 100
