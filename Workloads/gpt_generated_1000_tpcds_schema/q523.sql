WITH
    sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)   -- approximate 10% random sample
    ),
    sales_agg AS (
        SELECT
            ss_sold_date_sk,
            ss_store_sk,
            ss_customer_sk,
            ss_promo_sk,
            COUNT(*) AS txns,
            SUM(ss_ext_sales_price) AS total_sales,
            SUM(ss_ext_discount_amt) AS total_discount,
            SUM(ss_ext_tax) AS total_tax,
            AVG(ss_quantity) AS avg_quantity,
            CASE WHEN SUM(ss_ext_discount_amt) > 0 THEN 1 ELSE 0 END AS has_discount
        FROM sampled_sales
        GROUP BY ss_sold_date_sk, ss_store_sk, ss_customer_sk, ss_promo_sk
    ),
    inventory_agg AS (
        SELECT
            inv_date_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        GROUP BY inv_date_sk, inv_warehouse_sk
    ),
    store_hours_expanded AS (
        SELECT
            s.s_store_sk,
            hour_part
        FROM store s
        CROSS JOIN UNNEST(split(s.s_hours, '-')) AS t(hour_part)
    )
SELECT
    d.d_year,
    s.s_state,
    c.c_preferred_cust_flag,
    p.p_promo_name,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(sa.total_sales) AS sum_sales,
    SUM(sa.total_discount) AS sum_discount,
    AVG(sa.avg_quantity) AS avg_quantity_per_txn,
    SUM(ia.total_on_hand) AS sum_inventory_on_hand,
    CASE
        WHEN SUM(sa.total_discount) > 0 THEN 'Discounted'
        ELSE 'Full Price'
    END AS overall_sale_type,
    COUNT(*) FILTER (WHERE sh.hour_part = '8AM') AS cnt_store_open_8am
FROM sales_agg sa
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON sa.ss_customer_sk = c.c_customer_sk
JOIN inventory_agg ia
    ON d.d_date_sk = ia.inv_date_sk
JOIN store_hours_expanded sh
    ON s.s_store_sk = sh.s_store_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND p.p_channel_email = 'N'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY d.d_year, s.s_state, c.c_preferred_cust_flag, p.p_promo_name
ORDER BY sum_sales DESC
LIMIT 100
