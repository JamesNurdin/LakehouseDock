WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_total
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_item_sk
),
cs_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total
    FROM catalog_sales cs
    GROUP BY cs.cs_ship_mode_sk, cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_promo_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
intersect_cust AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001
    )
    INTERSECT
    SELECT wr.wr_refunded_customer_sk
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (
        SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001
    )
),
combined_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.store_sales_total,
        cs.cs_ship_mode_sk,
        cs.catalog_sales_total,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_promo_sk,
        ss.ss_sold_date_sk AS ss_sold_date_sk,
        cs.cs_sold_date_sk AS cs_sold_date_sk
    FROM ss_agg ss
    FULL OUTER JOIN cs_agg cs
        ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
        AND ss.ss_item_sk = cs.cs_item_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    i.i_brand,
    p.p_promo_name,
    sm.sm_type,
    ib.ib_upper_bound,
    c.c_first_name,
    c.c_last_name,
    ws.web_name,
    SUM(
        COALESCE(combined_agg.store_sales_total, 0) +
        COALESCE(combined_agg.catalog_sales_total, 0) -
        COALESCE(wr.total_return_amount, 0)
    ) AS net_sales,
    AVG(
        COALESCE(combined_agg.store_sales_total, 0) +
        COALESCE(combined_agg.catalog_sales_total, 0)
    ) AS avg_sales,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers
FROM combined_agg
JOIN date_dim d
    ON d.d_date_sk = COALESCE(combined_agg.ss_sold_date_sk, combined_agg.cs_sold_date_sk)
LEFT JOIN store s
    ON s.s_store_sk = combined_agg.ss_store_sk
LEFT JOIN item i
    ON i.i_item_sk = COALESCE(combined_agg.ss_item_sk, combined_agg.cs_item_sk)
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = combined_agg.cs_ship_mode_sk
LEFT JOIN promotion p
    ON p.p_promo_sk = combined_agg.cs_promo_sk
JOIN customer c
    ON c.c_preferred_cust_flag = 'Y'
JOIN intersect_cust ic
    ON ic.cust_sk = c.c_customer_sk
LEFT JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN wr_agg wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND ib.ib_upper_bound <= 100000
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND sm.sm_type = 'AIR'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY d.d_year, s.s_store_name, i.i_brand, p.p_promo_name, sm.sm_type, ib.ib_upper_bound, c.c_first_name, c.c_last_name, ws.web_name
HAVING SUM(
        COALESCE(combined_agg.store_sales_total, 0) +
        COALESCE(combined_agg.catalog_sales_total, 0) -
        COALESCE(wr.total_return_amount, 0)
    ) > 10000
ORDER BY net_sales DESC
LIMIT 100
