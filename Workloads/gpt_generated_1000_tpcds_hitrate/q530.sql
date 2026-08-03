WITH eligible_items AS (
    SELECT DISTINCT i_item_sk
    FROM item
    WHERE i_brand = 'BrandX'
),
base_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        w.w_city,
        cc.cc_name,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        sr.sr_return_amt,
        r.r_reason_desc,
        wp.wp_max_ad_count,
        i.i_item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON cs.cs_item_sk = sr.sr_item_sk
                               AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
                              AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
                           AND d.d_date_sk = wp.wp_creation_date_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq BETWEEN 120 AND 130
      AND w.w_state = 'CA'
      AND cc.cc_market_manager = 'John Doe'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%damaged%'
      AND wp.wp_max_ad_count >= 2
      AND EXISTS (SELECT 1 FROM promotion p2
                  WHERE p2.p_item_sk = i.i_item_sk
                    AND p2.p_discount_active = 'Y')
      AND i.i_item_sk IN (SELECT i_item_sk FROM eligible_items)
)
SELECT
    d_year,
    i_category,
    w_city,
    cc_name,
    SUM(cs_net_paid) AS total_sales,
    SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    LAG(SUM(cs_net_paid)) OVER (PARTITION BY i_category ORDER BY d_month_seq) AS prior_month_sales
FROM base_sales
GROUP BY d_year, i_category, w_city, cc_name, d_month_seq
HAVING COUNT(*) > 10
ORDER BY total_sales DESC
LIMIT 100
