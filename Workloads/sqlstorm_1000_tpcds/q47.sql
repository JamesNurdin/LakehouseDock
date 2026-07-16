WITH returns_agg AS (
    SELECT cr_order_number, cr_item_sk, sum(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_order_number, cr_item_sk
)
SELECT
    d_year,
    cc_name,
    i_category,
    p_promo_name,
    total_sales,
    coalesce(total_return_amount, 0) AS total_returns,
    total_sales - coalesce(total_return_amount, 0) AS net_sales,
    row_number() OVER (ORDER BY total_sales - coalesce(total_return_amount, 0) DESC) AS rank
FROM (
    SELECT
        d.d_year AS d_year,
        cc.cc_name AS cc_name,
        i.i_category AS i_category,
        p.p_promo_name AS p_promo_name,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(r.total_return_amount) AS total_return_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN returns_agg r ON cs.cs_order_number = r.cr_order_number AND cs.cs_item_sk = r.cr_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cc.cc_name, i.i_category, p.p_promo_name
) t
ORDER BY net_sales DESC
LIMIT 100
