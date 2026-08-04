WITH sales_enriched AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        cp.cp_department,
        cp.cp_catalog_number,
        p.p_discount_active,
        sm.sm_type,
        w.w_warehouse_name,
        s.s_store_name,
        s.s_division_name
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cp.cp_department = 'Sports'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_cost > 1000
      )
)
SELECT
    se.s_store_name,
    se.s_division_name,
    se.w_warehouse_name,
    se.cp_department,
    se.cp_catalog_number,
    se.sold_date,
    se.ship_date,
    se.cs_quantity,
    se.cs_ext_sales_price,
    CASE WHEN se.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    AVG(se.cs_net_profit) OVER (PARTITION BY se.s_division_name) AS avg_division_profit,
    ROW_NUMBER() OVER (PARTITION BY se.s_division_name ORDER BY se.cs_net_profit DESC) AS profit_rank,
    (SELECT AVG(cs3.cs_net_profit)
     FROM catalog_sales cs3
     JOIN catalog_page cp3 ON cs3.cs_catalog_page_sk = cp3.cp_catalog_page_sk
     WHERE cp3.cp_department = se.cp_department) AS dept_avg_profit,
    metric
FROM sales_enriched se
CROSS JOIN UNNEST(ARRAY[se.cs_quantity, CAST(se.cs_ext_sales_price AS double)]) AS t(metric)
WHERE metric > 0
ORDER BY profit_rank ASC, sold_date DESC
LIMIT 100
