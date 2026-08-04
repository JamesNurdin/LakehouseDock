WITH inv_agg AS (
   SELECT w.w_warehouse_sk,
          d.d_date,
          SUM(i.inv_quantity_on_hand) AS total_on_hand
   FROM inventory i
   JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
   JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_sk, d.d_date
),
sales_agg AS (
   SELECT w.w_warehouse_sk,
          d.d_date,
          SUM(cs.cs_net_paid) AS total_sales
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_sk, d.d_date
),
full_warehouse AS (
   SELECT COALESCE(i.w_warehouse_sk, s.w_warehouse_sk)   AS warehouse_sk,
          COALESCE(i.d_date, s.d_date)                 AS sale_date,
          i.total_on_hand,
          s.total_sales
   FROM inv_agg i
   FULL OUTER JOIN sales_agg s
     ON i.w_warehouse_sk = s.w_warehouse_sk
    AND i.d_date = s.d_date
),
promo_recent AS (
   SELECT p.p_promo_sk,
          p.p_promo_name,
          d.d_date AS promo_date,
          p.p_discount_active
   FROM promotion p
   JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
promo_ended AS (
   SELECT p.p_promo_sk,
          p.p_promo_name,
          d.d_date AS promo_date,
          p.p_discount_active
   FROM promotion p
   JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
promo_union AS (
   SELECT p.p_promo_sk,
          p.p_promo_name,
          p.promo_date,
          p.p_discount_active
   FROM promo_recent p
   UNION
   SELECT p.p_promo_sk,
          p.p_promo_name,
          p.promo_date,
          p.p_discount_active
   FROM promo_ended p
),
promo_final AS (
   SELECT pu.p_promo_sk,
          pu.p_promo_name,
          pu.promo_date
   FROM promo_union pu
   EXCEPT
   SELECT p.p_promo_sk,
          p.p_promo_name,
          d.d_date
   FROM promotion p
   JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
   WHERE d.d_year < 2001
)
SELECT fw.warehouse_sk,
       fw.sale_date,
       fw.total_on_hand,
       fw.total_sales,
       NULL AS p_promo_sk,
       NULL AS p_promo_name,
       NULL AS promo_date
FROM full_warehouse fw
WHERE fw.total_sales > 1000

UNION

SELECT NULL AS warehouse_sk,
       NULL AS sale_date,
       NULL AS total_on_hand,
       NULL AS total_sales,
       pf.p_promo_sk,
       pf.p_promo_name,
       pf.promo_date
FROM promo_final pf
WHERE pf.promo_date > DATE '2001-01-01'

ORDER BY warehouse_sk, p_promo_sk
