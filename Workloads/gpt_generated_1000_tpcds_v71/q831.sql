WITH all_data AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        wp.wp_url,
        ss.ss_net_profit,
        cs.cs_net_profit,
        ws.ws_net_profit,
        cr.cr_net_loss
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON i.i_item_sk = ss.ss_item_sk
        AND i.i_item_sk = cs.cs_item_sk
        AND i.i_item_sk = ws.ws_item_sk
    JOIN tpcds.promotion p
        ON p.p_promo_sk = ss.ss_promo_sk
        AND p.p_promo_sk = cs.cs_promo_sk
        AND p.p_promo_sk = ws.ws_promo_sk
    JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN tpcds.reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#12'
      AND p.p_purpose = 'Discount'
)
SELECT
    d_date,
    i_item_sk,
    i_product_name,
    i_category,
    i_brand,
    p_promo_name,
    wp_url,
    (COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(cr_net_loss, 0)) AS total_profit,
    RANK() OVER (PARTITION BY d_date ORDER BY (COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(cr_net_loss, 0)) DESC) AS profit_rank,
    SUM(COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(cr_net_loss, 0))
        OVER (PARTITION BY i_category ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_category
FROM all_data
ORDER BY d_date DESC, profit_rank
LIMIT 100
