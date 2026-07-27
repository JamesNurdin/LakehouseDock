WITH per_state_brand AS (
   SELECT
       ca.ca_state,
       i.i_brand,
       d.d_year,
       COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
       SUM(p.p_cost) AS total_promo_cost,
       SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.9 ELSE p.p_cost END) AS adjusted_total_cost
   FROM tpcds.customer c
   JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN tpcds.date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
   JOIN tpcds.promotion p ON p.p_start_date_sk = d.d_date_sk
   JOIN tpcds.item i ON p.p_item_sk = i.i_item_sk
   WHERE ca.ca_state IN ('TX', 'MS')
     AND ca.ca_city LIKE 'L%'
     AND c.c_salutation = 'Mr.'
     AND c.c_birth_year BETWEEN 1970 AND 1990
     AND d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
     AND p.p_channel_press = 'N'
   GROUP BY ca.ca_state, i.i_brand, d.d_year
   HAVING SUM(p.p_cost) > 500
), final_agg AS (
   SELECT
       ca_state,
       AVG(total_promo_cost) AS avg_total_cost,
       SUM(distinct_customers) AS total_customers,
       COUNT(*) AS brand_count
   FROM per_state_brand
   GROUP BY ca_state
)
SELECT DISTINCT
   ca_state,
   avg_total_cost,
   total_customers,
   brand_count
FROM final_agg
ORDER BY avg_total_cost DESC
LIMIT 100
