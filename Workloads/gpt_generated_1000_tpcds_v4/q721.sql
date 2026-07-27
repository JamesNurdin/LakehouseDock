WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        i.i_product_name,
        p.p_promo_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY i.i_item_id, i.i_item_sk, i.i_product_name, p.p_promo_name, d.d_year
),

returns_agg AS (
    SELECT
        i.i_item_id,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        AVG(wp.wp_max_ad_count) AS avg_wp_max_ad
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d2.d_date_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY i.i_item_id
)

SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.p_promo_name,
    sa.d_year,
    sa.total_sales,
    COALESCE(ra.store_return_amt, 0) + COALESCE(ra.web_return_amt, 0) AS total_return_amt,
    sa.total_profit - COALESCE(ra.store_net_loss, 0) - COALESCE(ra.web_net_loss, 0) AS net_profit,
    CASE
        WHEN (sa.total_profit - COALESCE(ra.store_net_loss, 0) - COALESCE(ra.web_net_loss, 0)) > 10000 THEN 'High'
        WHEN (sa.total_profit - COALESCE(ra.store_net_loss, 0) - COALESCE(ra.web_net_loss, 0)) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY sa.i_item_id ORDER BY sa.total_sales DESC) AS sales_rank,
    (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = i.i_item_sk) AS total_orders_for_item,
    ra.avg_wp_max_ad
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.i_item_id = ra.i_item_id
JOIN item i ON sa.i_item_sk = i.i_item_sk
WHERE sa.total_sales > 1000
ORDER BY net_profit DESC
LIMIT 100
