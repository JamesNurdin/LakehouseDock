WITH sales_agg AS (
    SELECT
        d.d_year,
        s.s_store_id,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High'
            ELSE 'Low'
        END AS sales_level
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON ss.ss_sold_date_sk = inv.inv_date_sk
                      AND ss.ss_item_sk = inv.inv_item_sk
    WHERE d.d_year = 2002
      AND d.d_moy IN (8, 9, 12)
      AND s.s_market_id IN (1, 3, 7)
      AND i.i_brand_id = 10
      AND inv.inv_quantity_on_hand > 0
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, s.s_store_id, i.i_category, p.p_promo_name
)
SELECT
    sa.d_year,
    sa.s_store_id,
    sa.i_category,
    sa.p_promo_name,
    sa.total_sales,
    sa.total_profit,
    sa.sales_level,
    sa.total_sales / NULLIF(sa.sales_cnt, 0) AS avg_sales_per_txn
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    WHERE i2.i_category = sa.i_category
      AND d2.d_year = sa.d_year
      AND wr.wr_return_amt > 0
)
ORDER BY sa.total_sales DESC, sa.s_store_id
LIMIT 100
