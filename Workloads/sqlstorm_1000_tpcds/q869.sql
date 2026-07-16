WITH unified_sales AS (
    SELECT 
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS channel_sk,
        'CALL_CENTER' AS sales_channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_tax AS tax,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        'STORE' AS sales_channel,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        'WEB' AS sales_channel,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_promo_sk
    FROM web_sales ws
),
aggregated_sales AS (
    SELECT 
        us.sales_channel,
        d.d_year,
        us.item_sk,
        i.i_product_name AS product_name,
        i.i_brand AS brand_name,
        i.i_category AS category_name,
        SUM(us.quantity) AS total_quantity,
        SUM(us.net_paid) AS total_net_paid,
        SUM(us.net_profit) AS total_net_profit,
        SUM(us.discount_amt) AS total_discount,
        COUNT(*) AS transaction_count,
        AVG(us.net_profit) AS avg_profit_per_txn,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY 
        us.sales_channel,
        d.d_year,
        us.item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        COALESCE(p.p_promo_name, 'No Promo')
),
ranked_sales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_channel, d_year ORDER BY total_net_profit DESC) AS rn
    FROM aggregated_sales
),
promo_stats AS (
    SELECT 
        sales_channel,
        d_year,
        promo_name,
        SUM(total_net_profit) AS promo_net_profit,
        COUNT(DISTINCT item_sk) AS promo_unique_items
    FROM aggregated_sales
    GROUP BY 
        sales_channel,
        d_year,
        promo_name
),
final_sales AS (
    SELECT 
        rs.sales_channel,
        rs.d_year,
        rs.rn,
        rs.item_sk,
        rs.product_name,
        rs.brand_name,
        rs.category_name,
        rs.total_quantity,
        rs.total_net_paid,
        rs.total_net_profit,
        rs.total_discount,
        rs.transaction_count,
        rs.avg_profit_per_txn,
        rs.promo_name,
        COALESCE(ps.promo_net_profit, 0) AS promo_total_net_profit,
        COALESCE(ps.promo_unique_items, 0) AS promo_item_count,
        CASE 
            WHEN rs.total_net_paid = 0 THEN NULL
            ELSE round((rs.total_net_profit / rs.total_net_paid) * 100, 2)
        END AS profit_margin_percent,
        concat(rs.brand_name, ' - ', rs.product_name) AS brand_product
    FROM ranked_sales rs
    LEFT JOIN promo_stats ps 
        ON rs.sales_channel = ps.sales_channel 
        AND rs.d_year = ps.d_year 
        AND rs.promo_name = ps.promo_name
    WHERE rs.rn <= 10
)
SELECT 
    f.*,
    (SELECT SUM(us.net_profit) FROM unified_sales us WHERE us.item_sk = f.item_sk) AS total_net_profit_all_time,
    (SELECT AVG(us.discount_amt) FROM unified_sales us WHERE us.item_sk = f.item_sk) * 100 AS avg_discount_percent_all_time
FROM final_sales f
ORDER BY f.sales_channel, f.d_year, f.rn
