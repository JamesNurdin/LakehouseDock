/*
  Goal: Identify the top 3 warehouse states (by total catalog sales) for the year 2001, 
  breaking down sales by promotion and showing key customer and inventory metrics. 
  The query joins all 16 selected TPC‑DS tables using only the allowed join keys, 
  applies more than six realistic filters, uses a CTE, a LATERAL subquery, an EXISTS subquery, 
  an INTERSECT-derived table, aggregates with multiple measures, computes a CASE‑based flag, 
  ranks rows per state with a window function, and returns the top‑k rows per group.
*/
WITH date_filt AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
),
intersect_warehouses AS (
    SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA'
    INTERSECT
    SELECT w_warehouse_sk FROM warehouse WHERE w_zip = '59275'
),
base AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state               AS w_state,
        df.d_year               AS d_year,
        p.p_promo_name          AS p_promo_name,
        cs.cs_ext_sales_price   AS cs_ext_sales_price,
        ws.ws_ext_sales_price   AS ws_ext_sales_price,
        c.c_customer_sk         AS c_customer_sk,
        sr.sr_return_amt        AS sr_return_amt,
        i.inv_quantity_on_hand  AS inv_quantity_on_hand,
        cs.cs_quantity,
        ws.ws_quantity,
        p.p_channel_demo,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        c.c_birth_year,
        sr.sr_fee,
        l.avg_qty_by_cc
    FROM date_filt df
    JOIN store_returns sr               ON sr.sr_returned_date_sk = df.d_date_sk
    JOIN customer c                     ON c.c_customer_sk = sr.sr_customer_sk
    JOIN customer_address ca            ON ca.ca_address_sk = sr.sr_addr_sk
    JOIN customer_demographics cd       ON cd.cd_demo_sk = sr.sr_cdemo_sk
    JOIN household_demographics hd      ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN income_band ib                 ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN catalog_sales cs              ON cs.cs_sold_date_sk = df.d_date_sk
    JOIN call_center cc                ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN catalog_page cp               ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN promotion p                   ON p.p_promo_sk = cs.cs_promo_sk
    JOIN warehouse w                   ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN inventory i                  ON i.inv_date_sk = df.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws                 ON ws.ws_sold_date_sk = df.d_date_sk
    JOIN web_page wp                  ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site wsit                ON wsit.web_site_sk = ws.ws_web_site_sk
    JOIN intersect_warehouses iw      ON iw.w_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT avg(cs3.cs_quantity) AS avg_qty_by_cc
        FROM catalog_sales cs3
        WHERE cs3.cs_call_center_sk = cc.cc_call_center_sk
    ) l ON TRUE
    WHERE
        w.w_state = 'CA'
        AND w.w_zip = '59275'
        AND p.p_channel_demo = 'N'
        AND ib.ib_upper_bound <= 100000
        AND hd.hd_vehicle_count >= 2
        AND c.c_birth_year BETWEEN 1950 AND 1960
        AND cs.cs_quantity > 5
        AND ws.ws_quantity > 3
        AND sr.sr_fee > 30
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_type = 'A' AND cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
        )
)
SELECT
    w_state,
    d_year,
    p_promo_name,
    sum_catalog_sales,
    sum_web_sales,
    distinct_customers,
    avg_return_amount,
    min_inventory,
    sales_category
FROM (
    SELECT
        w_state,
        d_year,
        p_promo_name,
        SUM(cs_ext_sales_price)        AS sum_catalog_sales,
        SUM(ws_ext_sales_price)        AS sum_web_sales,
        COUNT(DISTINCT c_customer_sk)  AS distinct_customers,
        AVG(sr_return_amt)             AS avg_return_amount,
        MIN(inv_quantity_on_hand)      AS min_inventory,
        CASE WHEN SUM(cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY SUM(cs_ext_sales_price) DESC) AS rn
    FROM base
    GROUP BY w_state, d_year, p_promo_name
) t
WHERE rn <= 3
ORDER BY w_state, sum_catalog_sales DESC
LIMIT 100
