WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 0
    GROUP BY cs.cs_bill_customer_sk,
             cs.cs_item_sk,
             cs.cs_promo_sk,
             cs.cs_sold_date_sk,
             cs.cs_catalog_page_sk
),
ws_full AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_reason_sk,
        wr.wr_returned_date_sk
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    i.i_item_id,
    i.i_product_name,
    p1.p_promo_name,
    p1.p_discount_active,
    d_sales.d_year AS sales_year,
    d_ws.d_year AS ws_year,
    s.s_store_name,
    cc.cc_name AS call_center_name,
    cp.cp_type AS catalog_page_type,
    wp.wp_url,
    r.r_reason_desc,
    ws_site.web_name AS website_name,
    cs_agg.total_sales_price,
    cs_agg.total_quantity,
    cs_agg.total_net_profit,
    ws_full.ws_ext_sales_price,
    ws_full.ws_quantity,
    ws_full.wr_return_amt,
    CASE
        WHEN cs_agg.total_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs_agg.total_sales_price DESC) AS sales_rank,
    (SELECT COUNT(*) FROM web_returns wr_sub WHERE wr_sub.wr_order_number = ws_full.ws_order_number) AS related_return_count
FROM cs_agg
INNER JOIN customer c
    ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
INNER JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
INNER JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
INNER JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
INNER JOIN promotion p1
    ON cs_agg.cs_promo_sk = p1.p_promo_sk
INNER JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN date_dim d_sales
    ON cs_agg.cs_sold_date_sk = d_sales.d_date_sk
INNER JOIN ws_full
    ON cs_agg.cs_bill_customer_sk = ws_full.ws_bill_customer_sk
   AND cs_agg.cs_item_sk = ws_full.ws_item_sk
INNER JOIN date_dim d_ws
    ON ws_full.ws_sold_date_sk = d_ws.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_sales.d_date_sk
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
LEFT JOIN web_page wp
    ON ws_full.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws_site
    ON ws_full.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN promotion p2
    ON ws_full.ws_promo_sk = p2.p_promo_sk
LEFT JOIN reason r
    ON ws_full.wr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d_cp
    ON cp.cp_start_date_sk = d_cp.d_date_sk
LEFT JOIN date_dim d_wp
    ON wp.wp_creation_date_sk = d_wp.d_date_sk
LEFT JOIN date_dim d_promo
    ON p1.p_start_date_sk = d_promo.d_date_sk
LEFT JOIN date_dim d_site
    ON ws_site.web_open_date_sk = d_site.d_date_sk
WHERE d_sales.d_year = 1998
  AND s.s_state = 'CA'
  AND p1.p_discount_active = 'Y'
  AND i.i_color = 'Red'
LIMIT 100
