WITH sales_cte AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        d.d_date,
        c.c_customer_sk,
        p.p_promo_name,
        cc.cc_city,
        wp.wp_url,
        regexp_extract(p.p_promo_name, 'Promo-(\\d{4})', 1) AS promo_year_extracted
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.example\\.com/.*$')
      AND regexp_like(p.p_promo_name, 'Promo-202[0-5]')
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
            AND cr.cr_net_loss > 0
      )
)
SELECT
    sales_cte.cc_city AS city,
    sales_cte.p_promo_name AS promo_name,
    sales_cte.promo_year_extracted AS promo_year,
    CONCAT(sales_cte.cc_city, ' - ', sales_cte.p_promo_name) AS city_promo_label,
    SUM(sales_cte.cs_net_profit) AS total_profit,
    COUNT(DISTINCT sales_cte.cs_order_number) AS order_count,
    AVG(sales_cte.cs_net_paid) AS avg_net_paid
FROM sales_cte
GROUP BY
    sales_cte.cc_city,
    sales_cte.p_promo_name,
    sales_cte.promo_year_extracted,
    CONCAT(sales_cte.cc_city, ' - ', sales_cte.p_promo_name)
HAVING SUM(sales_cte.cs_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
