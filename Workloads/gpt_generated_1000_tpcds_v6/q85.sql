WITH high_income_hdemo AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 120000
)
SELECT
    sold_date_sk,
    i_item_id,
    i_product_name,
    sales_amount,
    profit_category,
    avg_catalog_discount,
    sales_channel
FROM (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        i.i_item_id,
        i.i_product_name,
        ss.ss_ext_sales_price AS sales_amount,
        CASE WHEN ss.ss_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_category,
        (SELECT avg(cs.cs_ext_discount_amt)
         FROM catalog_sales cs
         WHERE cs.cs_item_sk = i.i_item_sk) AS avg_catalog_discount,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_hdemo_sk IN (SELECT hd_demo_sk FROM high_income_hdemo)
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453000

    UNION ALL

    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        i.i_item_id,
        i.i_product_name,
        cs.cs_ext_sales_price AS sales_amount,
        CASE WHEN cs.cs_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_category,
        (SELECT avg(cs2.cs_ext_discount_amt)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_catalog_discount,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_bill_hdemo_sk IN (SELECT hd_demo_sk FROM high_income_hdemo)
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453000
) combined
ORDER BY sales_amount DESC
LIMIT 100
