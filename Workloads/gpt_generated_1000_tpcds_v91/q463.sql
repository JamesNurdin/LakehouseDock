WITH base_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        td.t_hour,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_count
    FROM store_sales ss
    RIGHT OUTER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND regexp_like(p.p_channel_details, '^Old')
    LEFT JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE i.i_product_name LIKE '%Chocolate%'
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        td.t_hour
),
ranked_sales AS (
    SELECT
        bs.*,
        ROW_NUMBER() OVER (PARTITION BY bs.i_brand ORDER BY bs.total_net_profit DESC) AS brand_profit_rank
    FROM base_sales bs
)
SELECT
    rs.i_item_sk,
    rs.i_product_name,
    rs.i_brand,
    rs.i_category,
    substring(rs.i_product_name, 1, 10) AS product_name_prefix,
    regexp_extract(rs.i_product_name, '(\\w+)', 1) AS first_word,
    rs.p_promo_name,
    rs.t_hour,
    rs.total_quantity,
    round(rs.total_sales, 2) AS total_sales,
    round(rs.total_net_profit, 2) AS total_net_profit,
    round(rs.avg_discount, 2) AS avg_discount,
    rs.sales_count,
    rs.brand_profit_rank,
    concat(substring(rs.i_product_name, 1, 10), ' ', coalesce(rs.p_promo_name, 'NoPromo')) AS product_promo_label,
    (SELECT AVG(cs.cs_net_paid)
       FROM catalog_sales cs
       WHERE cs.cs_item_sk = rs.i_item_sk) AS avg_catalog_net_paid
FROM ranked_sales rs
WHERE rs.brand_profit_rank <= 5
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN household_demographics hd
            ON ss2.ss_hdemo_sk = hd.hd_demo_sk
        WHERE ss2.ss_item_sk = rs.i_item_sk
          AND hd.hd_buy_potential = '5001-10000'
          AND ss2.ss_quantity > 0
        LIMIT 1
    )
ORDER BY rs.total_net_profit DESC
LIMIT 100
