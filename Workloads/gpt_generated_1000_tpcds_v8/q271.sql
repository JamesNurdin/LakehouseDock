WITH sales_union AS (
    SELECT
        s.s_store_id        AS location_id,
        d.d_year            AS year,
        CASE
            WHEN hd.hd_buy_potential = '>10000'      THEN 'High'
            WHEN hd.hd_buy_potential = '5001-10000'  THEN 'Medium'
            ELSE 'Low'
        END                AS buy_category,
        ss.ss_net_paid_inc_tax AS sales_amount,
        ib.ib_lower_bound  AS income_lower_bound
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN LATERAL (
        SELECT SUM(cs.cs_ext_sales_price) AS cat_sales
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = c.c_customer_sk
          AND cs.cs_sold_date_sk = d.d_date_sk
    ) cat ON TRUE
    WHERE s.s_state = 'CA'
      AND d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_customer_sk = c.c_customer_sk
              AND sr.sr_returned_date_sk = d.d_date_sk
              AND sr.sr_net_loss > 0
        )
),
web_sales_union AS (
    SELECT
        wp.wp_web_page_id   AS location_id,
        d.d_year            AS year,
        CASE
            WHEN hd.hd_buy_potential = '>10000'      THEN 'High'
            WHEN hd.hd_buy_potential = '5001-10000'  THEN 'Medium'
            ELSE 'Low'
        END                AS buy_category,
        ws.ws_net_paid_inc_tax AS sales_amount,
        ib.ib_lower_bound  AS income_lower_bound
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN LATERAL (
        SELECT SUM(cs.cs_ext_sales_price) AS cat_sales
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = c.c_customer_sk
          AND cs.cs_sold_date_sk = d.d_date_sk
    ) cat ON TRUE
    WHERE wp.wp_type = 'article'
      AND d.d_year = 2001
)
SELECT
    location_id,
    year,
    buy_category,
    SUM(sales_amount)       AS total_sales,
    SUM(income_lower_bound) AS total_income_lower,
    COUNT(*)                AS txn_count
FROM (
    SELECT * FROM sales_union
    UNION
    SELECT * FROM web_sales_union
) u
GROUP BY ROLLUP (location_id, year, buy_category)
ORDER BY total_sales DESC
LIMIT 100
