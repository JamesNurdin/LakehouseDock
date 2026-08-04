WITH sales_agg AS (
   SELECT
     s.s_store_id,
     s.s_state,
     SUM(ss.ss_net_profit) AS total_profit,
     CASE WHEN s.s_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
     ARRAY[ i.i_category, i.i_brand ] AS attr_array
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND p.p_channel_email = 'Y'
   GROUP BY s.s_store_id, s.s_state, s.s_tax_percentage, i.i_category, i.i_brand
),
sales_unrolled AS (
   SELECT
     s_store_id,
     s_state,
     total_profit,
     tax_category,
     attr
   FROM sales_agg
   CROSS JOIN UNNEST(attr_array) AS t(attr)
),
returns_agg AS (
   SELECT
     s.s_store_id,
     s.s_state,
     SUM(-sr.sr_net_loss) AS total_profit,
     CASE WHEN s.s_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
     ARRAY[ i.i_category, i.i_brand ] AS attr_array
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY s.s_store_id, s.s_state, s.s_tax_percentage, i.i_category, i.i_brand
),
returns_unrolled AS (
   SELECT
     s_store_id,
     s_state,
     total_profit,
     tax_category,
     attr
   FROM returns_agg
   CROSS JOIN UNNEST(attr_array) AS t(attr)
),
combined AS (
   SELECT s_store_id, s_state, total_profit, tax_category, attr FROM sales_unrolled
   INTERSECT
   SELECT s_store_id, s_state, total_profit, tax_category, attr FROM returns_unrolled
),
ranked AS (
   SELECT
     s_store_id,
     s_state,
     total_profit,
     tax_category,
     attr,
     ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS rn,
     (SELECT AVG(total_profit) FROM sales_agg) AS avg_profit_overall
   FROM combined
)
SELECT
   s_store_id,
   s_state,
   total_profit,
   tax_category,
   attr,
   avg_profit_overall
FROM ranked
WHERE rn <= 3
ORDER BY s_state, total_profit DESC
OFFSET 0 FETCH NEXT 10 ROWS ONLY
