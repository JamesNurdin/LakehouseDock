WITH catalog_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim d
            WHERE d.d_year = 2001
              AND d.d_qoy = 1
              AND d.d_month_seq BETWEEN 1200 AND 1210
          )
      AND cs.cs_quantity > 0
      AND cs.cs_promo_sk IS NOT NULL
      AND cs.cs_catalog_page_sk IS NOT NULL
    GROUP BY cs.cs_warehouse_sk, cs.cs_sold_date_sk, cs.cs_promo_sk, cs.cs_catalog_page_sk
),
store_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim d
            WHERE d.d_year = 2001
              AND d.d_month_seq BETWEEN 1200 AND 1210
          )
      AND ss.ss_quantity > 0
      AND ss.ss_promo_sk IS NOT NULL
      AND ss.ss_sold_time_sk IN (
            SELECT t_time_sk FROM time_dim t
            WHERE t.t_hour BETWEEN 8 AND 18
          )
    GROUP BY ss.ss_sold_date_sk, ss.ss_sold_time_sk, ss.ss_customer_sk, ss.ss_promo_sk
)
SELECT
    w.w_warehouse_name,
    d.d_date,
    p.p_promo_name,
    cp.cp_description,
    SUM(ca.catalog_sales_amount) AS total_catalog_sales,
    SUM(sa.store_sales_amount) AS total_store_sales,
    inv.inv_quantity_on_hand,
    ARRAY_AGG(DISTINCT cp.cp_description) AS distinct_page_descriptions
FROM catalog_agg ca
JOIN catalog_page cp
      ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
      ON ca.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
      ON ca.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d
      ON ca.cs_sold_date_sk = d.d_date_sk
JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_agg sa
      ON sa.ss_sold_date_sk = d.d_date_sk
     AND sa.ss_promo_sk = p.p_promo_sk
JOIN customer c
      ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca_addr
      ON c.c_current_addr_sk = ca_addr.ca_address_sk
WHERE ca_addr.ca_country = 'United States'
  AND w.w_state = 'CA'
  AND p.p_channel_email = 'Y'
  AND cp.cp_catalog_number IN (5, 10, 15)
  AND d.d_qoy = 1
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND p2.p_promo_name LIKE '%Holiday%'
    )
GROUP BY w.w_warehouse_name,
         d.d_date,
         p.p_promo_name,
         cp.cp_description,
         inv.inv_quantity_on_hand
ORDER BY total_store_sales DESC
LIMIT 100
