WITH joined_data AS (
   SELECT
       d.d_year,
       ca.ca_state,
       i.i_category,
       i.i_brand,
       ss.ss_ext_sales_price        AS sales_amount,
       cr.cr_return_amount          AS return_amount,
       ss.ss_net_profit             AS net_profit,
       inv.inv_quantity_on_hand     AS qty_on_hand
   FROM store_sales ss
   JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i            ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                           AND cr.cr_returned_date_sk = d.d_date_sk
   JOIN inventory inv    ON inv.inv_item_sk = i.i_item_sk
                           AND inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND ca.ca_state = 'CA'
     AND i.i_brand = 'Brand#45'
),

agg_data AS (
   SELECT
       d_year,
       ca_state,
       i_category,
       i_brand,
       SUM(sales_amount)                     AS total_sales,
       SUM(COALESCE(return_amount, 0))        AS total_returns,
       SUM(net_profit)                        AS total_profit,
       AVG(qty_on_hand)                       AS avg_qty_on_hand
   FROM joined_data
   GROUP BY ROLLUP (d_year, ca_state, i_category, i_brand)
)

SELECT
   d_year,
   ca_state,
   i_category,
   i_brand,
   total_sales,
   total_returns,
   total_profit,
   avg_qty_on_hand,
   CASE WHEN total_sales = 0 THEN 0 ELSE total_profit / total_sales END AS profit_margin
FROM agg_data
WHERE total_sales > 10000
  AND total_profit > 500
  AND CASE WHEN total_sales = 0 THEN 0 ELSE total_profit / total_sales END > 0.05
ORDER BY d_year, ca_state, i_category, i_brand
