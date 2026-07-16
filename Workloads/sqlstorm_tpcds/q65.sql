WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS sales,
        SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND d.d_year = 2000
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_id, i.i_product_name, d.d_year
)
SELECT
    i_item_id,
    i_product_name,
    d_year,
    sales,
    profit,
    rn
FROM (
    SELECT
        i_item_id,
        i_product_name,
        d_year,
        sales,
        profit,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sales DESC) AS rn
    FROM sales_agg
) t
WHERE rn <= 10
ORDER BY sales DESC
