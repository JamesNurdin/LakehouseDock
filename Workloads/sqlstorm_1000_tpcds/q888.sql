WITH unified_sales AS (
   SELECT
       cs.cs_sold_date_sk AS sold_date_sk,
       cs.cs_bill_customer_sk AS customer_sk,
       cs.cs_item_sk AS item_sk,
       cs.cs_call_center_sk AS call_center_sk,
       NULL AS store_sk,
       cs.cs_promo_sk AS promo_sk,
       cs.cs_order_number AS order_number,
       cs.cs_quantity AS quantity,
       cs.cs_net_paid AS net_paid,
       cs.cs_net_profit AS net_profit,
       cs.cs_ext_sales_price AS ext_sales_price,
       cs.cs_ext_discount_amt AS ext_discount_amt,
       cs.cs_ext_tax AS ext_tax,
       cs.cs_ext_ship_cost AS ext_ship_cost,
       NULL AS web_page_sk,
       cs.cs_catalog_page_sk AS catalog_page_sk,
       'catalog' AS sales_channel
   FROM catalog_sales cs
   WHERE cs.cs_sold_date_sk IS NOT NULL

   UNION ALL

   SELECT
       ss.ss_sold_date_sk AS sold_date_sk,
       ss.ss_customer_sk AS customer_sk,
       ss.ss_item_sk AS item_sk,
       NULL AS call_center_sk,
       ss.ss_store_sk AS store_sk,
       ss.ss_promo_sk AS promo_sk,
       ss.ss_ticket_number AS order_number,
       ss.ss_quantity AS quantity,
       ss.ss_net_paid AS net_paid,
       ss.ss_net_profit AS net_profit,
       ss.ss_ext_sales_price AS ext_sales_price,
       ss.ss_ext_discount_amt AS ext_discount_amt,
       ss.ss_ext_tax AS ext_tax,
       NULL AS ext_ship_cost,
       NULL AS web_page_sk,
       NULL AS catalog_page_sk,
       'store' AS sales_channel
   FROM store_sales ss
   WHERE ss.ss_sold_date_sk IS NOT NULL
),
sales_with_dims AS (
   SELECT
       us.*,
       d.d_year,
       d.d_quarter_name,
       COALESCE(st.s_store_name, cc.cc_name) AS location_name,
       COALESCE(st.s_city, cc.cc_city) AS location_city,
       COALESCE(st.s_state, cc.cc_state) AS location_state,
       i.i_product_name,
       i.i_brand,
       p.p_promo_name,
       (us.ext_sales_price - us.ext_discount_amt + us.ext_tax) AS effective_price,
       (us.ext_sales_price + COALESCE(us.ext_ship_cost, 0)) AS total_including_ship,
       CASE
           WHEN (us.ext_sales_price - us.ext_discount_amt + us.ext_tax) = 0 THEN NULL
           ELSE us.net_profit / (us.ext_sales_price - us.ext_discount_amt + us.ext_tax)
       END AS profit_margin,
       CONCAT(
           COALESCE(st.s_store_name, cc.cc_name, ''),
           ' - ',
           COALESCE(st.s_city, cc.cc_city, ''),
           ', ',
           COALESCE(st.s_state, cc.cc_state, '')
       ) AS location_desc
   FROM unified_sales us
   LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
   LEFT JOIN store st ON us.store_sk = st.s_store_sk
   LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
   LEFT JOIN item i ON us.item_sk = i.i_item_sk
   LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
),
ranked_sales AS (
   SELECT
       swd.*,
       ROW_NUMBER() OVER (PARTITION BY swd.location_name, swd.d_year ORDER BY swd.net_profit DESC) AS profit_rank,
       COUNT(DISTINCT swd.customer_sk) OVER (PARTITION BY swd.location_name, swd.d_year) AS distinct_customers,
       (SELECT MAX(net_profit)
        FROM sales_with_dims swd2
        WHERE swd2.item_sk = swd.item_sk AND swd2.d_year = swd.d_year) AS item_max_yearly_profit,
       CASE
           WHEN COALESCE(swd.profit_margin, 0) > 0.25 THEN 'HIGH'
           ELSE 'NORMAL'
       END AS margin_category
   FROM sales_with_dims swd
   WHERE swd.net_profit IS NOT NULL AND swd.net_profit > 0
),
final_aggregates AS (
   SELECT
       rs.location_name,
       rs.location_city,
       rs.location_state,
       rs.d_year,
       COUNT(*) AS total_transactions,
       SUM(rs.quantity) AS total_quantity,
       SUM(rs.net_paid) AS total_net_paid,
       SUM(rs.net_profit) AS total_net_profit,
       AVG(rs.profit_margin) AS avg_profit_margin,
       MAX(rs.profit_margin) AS max_profit_margin,
       MIN(rs.profit_margin) AS min_profit_margin,
       COUNT(DISTINCT rs.item_sk) AS distinct_items_sold,
       COUNT(DISTINCT CASE WHEN rs.margin_category = 'HIGH' THEN rs.item_sk END) AS high_margin_items,
       SUM(rs.net_paid + COALESCE(rs.ext_ship_cost, 0)) - SUM(rs.ext_discount_amt) AS adjusted_revenue,
       CONCAT_WS(', ', ARRAY_DISTINCT(ARRAY_AGG(DISTINCT i.i_brand))) AS brands_sold
   FROM ranked_sales rs
   LEFT JOIN item i ON rs.item_sk = i.i_item_sk
   GROUP BY rs.location_name, rs.location_city, rs.location_state, rs.d_year
   HAVING SUM(rs.net_profit) > 10000
)
SELECT
   fa.location_name,
   fa.location_city,
   fa.location_state,
   fa.d_year,
   fa.total_transactions,
   fa.total_quantity,
   ROUND(fa.total_net_paid, 2) AS total_net_paid,
   ROUND(fa.total_net_profit, 2) AS total_net_profit,
   ROUND(fa.avg_profit_margin, 4) AS avg_profit_margin,
   fa.max_profit_margin,
   fa.min_profit_margin,
   fa.distinct_items_sold,
   fa.high_margin_items,
   ROUND(fa.adjusted_revenue, 2) AS adjusted_revenue,
   fa.brands_sold
FROM final_aggregates fa
ORDER BY fa.d_year DESC, fa.total_net_profit DESC
LIMIT 100
