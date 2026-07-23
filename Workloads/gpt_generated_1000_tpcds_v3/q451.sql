WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
)
SELECT DISTINCT
    w.w_warehouse_name,
    cc.cc_name AS call_center_name,
    wp.wp_url,
    cs_agg.total_ext_sales_price,
    cs_agg.total_quantity,
    cs_agg.total_net_profit,
    ws.ws_net_paid,
    sr.sr_net_loss,
    p.p_promo_name,
    c.c_customer_id,
    RANK() OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY (cs_agg.total_ext_sales_price + ws.ws_net_paid) DESC
    ) AS sales_rank,
    CASE
        WHEN cs_agg.total_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM cs_agg
JOIN catalog_sales cs
    ON cs.cs_item_sk = cs_agg.cs_item_sk
    AND cs.cs_sold_date_sk = cs_agg.cs_sold_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
    AND wp.wp_customer_sk = c.c_customer_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE
    cc.cc_rec_start_date >= DATE '2001-01-01'
    AND cc.cc_rec_start_date <= DATE '2002-12-31'
    AND wp.wp_rec_start_date >= DATE '2000-01-01'
    AND wsit.web_rec_start_date >= DATE '2000-01-01'
    AND w.w_gmt_offset >= 0
ORDER BY
    sales_rank ASC,
    w.w_warehouse_name
LIMIT 100
