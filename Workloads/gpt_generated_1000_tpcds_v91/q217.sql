WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cr.cr_return_amount,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
),
agg_sales AS (
    SELECT
        d.d_year,
        cc.cc_name,
        SUBSTRING(cc.cc_name FROM 1 FOR 5) AS short_name,
        CASE WHEN cc.cc_state LIKE 'C%' THEN 'East' ELSE 'Other' END AS region_category,
        CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})') AS promo_year,
        SUM(COALESCE(sr.cs_net_paid_inc_tax, 0) - COALESCE(sr.cr_return_amount, 0)) AS net_revenue
    FROM sales_returns sr
    LEFT JOIN date_dim d
        ON COALESCE(sr.cs_sold_date_sk, sr.cr_returned_date_sk) = d.d_date_sk
    LEFT JOIN call_center cc
        ON sr.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p
        ON sr.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(p.p_promo_name, 'Discount')
      AND cc.cc_name LIKE 'A%'
    GROUP BY
        d.d_year,
        cc.cc_name,
        cc.cc_state,
        cc.cc_city,
        p.p_promo_name
)
SELECT
    d_year,
    cc_name,
    short_name,
    region_category,
    location,
    promo_year,
    net_revenue,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY net_revenue DESC) AS revenue_rank
FROM agg_sales
ORDER BY net_revenue DESC
LIMIT 100
