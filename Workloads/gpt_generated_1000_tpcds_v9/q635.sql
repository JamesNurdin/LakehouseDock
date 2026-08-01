WITH sales_agg AS (
    SELECT
        s.ss_item_sk,
        s.ss_store_sk,
        s.ss_promo_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_education_status,
        p.p_promo_name,
        p.p_discount_active,
        s.ss_quantity,
        s.ss_ext_sales_price,
        s.ss_net_paid,
        s.ss_net_profit,
        COALESCE(sr.sr_return_amt, 0) AS store_return_amt,
        COALESCE(cr.cr_return_amount, 0) AS catalog_return_amt,
        COALESCE(wr.wr_return_amt, 0) AS web_return_amt,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS is_discount_active
    FROM store_sales s
    JOIN item i ON s.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON s.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = s.ss_ticket_number
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 20
      AND p.p_cost < 5000
      AND cc.cc_country = 'United States'
      AND w.w_gmt_offset >= 0
),
agg_by_brand_category AS (
    SELECT
        i_brand AS brand,
        i_category AS category,
        p_promo_name AS promo_name,
        is_discount_active,
        ss_ext_sales_price AS ext_sales_price,
        store_return_amt,
        catalog_return_amt,
        web_return_amt,
        ss_net_profit AS net_profit
    FROM sales_agg
)
SELECT
    brand,
    category,
    promo_name,
    is_discount_active,
    SUM(ext_sales_price) AS total_sales,
    SUM(store_return_amt + catalog_return_amt + web_return_amt) AS total_returns,
    (SUM(ext_sales_price) - SUM(store_return_amt + catalog_return_amt + web_return_amt)) AS net_sales,
    AVG(net_profit) AS avg_profit,
    RANK() OVER (
        PARTITION BY brand
        ORDER BY (SUM(ext_sales_price) - SUM(store_return_amt + catalog_return_amt + web_return_amt)) DESC
    ) AS brand_category_rank,
    (SELECT COUNT(DISTINCT p2.p_promo_id) FROM promotion p2) AS total_promotions
FROM agg_by_brand_category
GROUP BY brand, category, promo_name, is_discount_active
HAVING SUM(ext_sales_price) > 10000
   AND SUM(store_return_amt + catalog_return_amt + web_return_amt) < 2000
   AND AVG(net_profit) > 0
   AND COUNT(*) >= 5
ORDER BY net_sales DESC
LIMIT 100
