/*
Goal: Identify top‑selling catalog pages by department for the year 2001 during the morning shift, flag active promotions, rank sales within each department, and exclude items that have high‑value sales elsewhere. The query demonstrates distinct selection, window ranking, CASE logic, anti‑joins (NOT IN, NOT EXISTS), a correlated subquery, a RIGHT OUTER JOIN, UNION, EXCEPT and final ordering with a LIMIT.
*/
WITH base AS (
    SELECT
        cp.cp_department               AS cp_department,
        d_sold.d_year                  AS d_year,
        t.t_hour                       AS t_hour,
        p.p_promo_name                 AS p_promo_name,
        cs.cs_net_paid_inc_ship_tax   AS cs_net_paid_inc_ship_tax,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_paid_inc_ship_tax DESC) AS dept_rank,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        cs.cs_item_sk                  AS cs_item_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    RIGHT JOIN date_dim d_page_end
        ON cp.cp_end_date_sk = d_page_end.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND d_sold.d_year = 2001
      AND t.t_sub_shift = 'morning'
      AND cs.cs_item_sk NOT IN (
          SELECT cs3.cs_item_sk
          FROM catalog_sales cs3
          WHERE cs3.cs_ext_discount_amt = 0
      )
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = cs.cs_item_sk
            AND cs2.cs_net_paid_inc_ship_tax > 5000
      )
      AND cs.cs_quantity > (
          SELECT AVG(cs_sub.cs_quantity)
          FROM catalog_sales cs_sub
          WHERE cs_sub.cs_sold_date_sk = cs.cs_sold_date_sk
      )
)
-- First component: distinct rows with high departmental rank
SELECT DISTINCT
    cp_department,
    d_year,
    t_hour,
    p_promo_name,
    cs_net_paid_inc_ship_tax,
    dept_rank,
    promo_status
FROM base
WHERE dept_rank <= 5

UNION

-- Second component: active promotions with sizable net paid amount
SELECT
    cp_department,
    d_year,
    t_hour,
    p_promo_name,
    cs_net_paid_inc_ship_tax,
    dept_rank,
    promo_status
FROM base
WHERE promo_status = 'Active'
  AND cs_net_paid_inc_ship_tax > 3000

EXCEPT

-- Exclude any rows belonging to the Electronics department (if present)
SELECT
    cp_department,
    d_year,
    t_hour,
    p_promo_name,
    cs_net_paid_inc_ship_tax,
    dept_rank,
    promo_status
FROM base
WHERE cp_department = 'Electronics'

ORDER BY cs_net_paid_inc_ship_tax DESC
LIMIT 100
