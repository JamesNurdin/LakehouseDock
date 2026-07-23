WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        i.i_category,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        i.i_item_id,
        regexp_extract(i.i_item_desc, '(?i)\\b(steel|plastic)\\b', 1) AS material,
        i.i_brand || ' - ' || i.i_category AS brand_category,
        p.p_promo_name,
        p.p_channel_tv,
        d.d_year,
        d.d_quarter_name,
        wp.wp_url,
        cd.cd_credit_rating
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i)\\b(steel|plastic)\\b')
      AND i.i_color LIKE 'Red%'
)
SELECT
    fs.i_category,
    fs.material,
    substr(fs.i_item_desc, 1, 30) AS item_desc_preview,
    count(DISTINCT fs.ws_order_number) AS distinct_orders,
    sum(fs.ws_net_profit) AS total_net_profit,
    avg(fs.ws_ext_sales_price) AS avg_ext_sales_price,
    CASE
        WHEN sum(fs.ws_net_profit) > 100000 THEN 'High Profit'
        WHEN sum(fs.ws_net_profit) > 0 THEN 'Moderate Profit'
        ELSE 'Low/Negative Profit'
    END AS profit_category,
    count(DISTINCT fs.p_promo_name) AS distinct_promotions,
    count(DISTINCT fs.cd_credit_rating) AS distinct_credit_ratings,
    max(fs.wp_url) AS sample_url,
    max(fs.brand_category) AS sample_brand_category
FROM filtered_sales fs
GROUP BY
    fs.i_category,
    fs.material,
    substr(fs.i_item_desc, 1, 30)
ORDER BY total_net_profit DESC
LIMIT 100
