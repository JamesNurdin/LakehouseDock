/* Goal: Analyze combined catalog and store sales performance for high‑value items and promotions, broken down by call center, customer demographics and income band, while limiting to large call centers and specific customer/income filters. */
WITH intersect_items AS (
    SELECT cs_item_sk AS item_sk
    FROM catalog_sales
    WHERE cs_coupon_amt > 2000.00
    INTERSECT
    SELECT i_item_sk
    FROM item
    WHERE i_brand = 'Brand#12'
),
ss_agg AS (
    SELECT
        ss_item_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(*) AS store_txn_cnt,
        AVG(ss_sales_price) AS avg_store_sales_price
    FROM store_sales
    TABLESAMPLE BERNOULLI (10) -- sample 10 % of rows
    WHERE ss_quantity > 1
    GROUP BY ss_item_sk, ss_promo_sk
)
SELECT
    cc.cc_name,
    i.i_item_id,
    p.p_promo_name,
    c.c_first_name,
    c.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    ss_agg.total_store_sales,
    ss_agg.store_txn_cnt
FROM catalog_sales cs
JOIN intersect_items ii
    ON cs.cs_item_sk = ii.item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN ss_agg
    ON ss_agg.ss_item_sk = i.i_item_sk
   AND ss_agg.ss_promo_sk = p.p_promo_sk
WHERE
    cc.cc_class = 'large'
    AND cc.cc_tax_percentage >= 0.05
    AND c.c_birth_year = 1965
    AND ib.ib_lower_bound >= 80000
    AND p.p_discount_active = 'Y'
GROUP BY
    cc.cc_name,
    i.i_item_id,
    p.p_promo_name,
    c.c_first_name,
    c.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss_agg.total_store_sales,
    ss_agg.store_txn_cnt
LIMIT 100
