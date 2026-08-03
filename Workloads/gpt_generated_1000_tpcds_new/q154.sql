WITH all_facts AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       i.i_brand,
       d.d_year,
       SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
       SUM(sr.sr_return_quantity) AS total_return_qty,
       AVG(inv.inv_quantity_on_hand) AS avg_on_hand,
       COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
       COUNT(DISTINCT ws.ws_order_number) AS web_orders,
       MIN(t.t_hour) AS earliest_return_hour,
       MAX(t.t_hour) AS latest_return_hour,
       MAX(cp.cp_department) AS catalog_department,
       MAX(ws_site.web_country) AS web_country
   FROM
       store_returns sr
       JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
       JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
       JOIN item i ON sr.sr_item_sk = i.i_item_sk
       JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d.d_date_sk
       JOIN promotion p ON p.p_item_sk = i.i_item_sk
       LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
           AND cs.cs_item_sk = i.i_item_sk
       LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
       LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
           AND ws.ws_item_sk = i.i_item_sk
       LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
       LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
       LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
       LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE
       d.d_year = 2001
       AND i.i_brand = 'Brand#12'
       AND p.p_channel_catalog = 'N'
       AND sr.sr_return_quantity > 10
       AND inv.inv_quantity_on_hand > 500
       AND t.t_hour BETWEEN 8 AND 18
       AND ws_site.web_country = 'United States'
   GROUP BY
       i.i_item_sk,
       i.i_product_name,
       i.i_brand,
       d.d_year
)
SELECT
   af.i_item_sk,
   af.i_product_name,
   af.i_brand,
   af.d_year,
   af.total_return_amount,
   af.total_return_qty,
   af.avg_on_hand,
   af.catalog_orders,
   af.web_orders,
   af.earliest_return_hour,
   af.latest_return_hour,
   af.catalog_department,
   af.web_country,
   RANK() OVER (PARTITION BY af.d_year ORDER BY af.total_return_amount DESC) AS yearly_return_rank,
   ROW_NUMBER() OVER (ORDER BY af.total_return_amount DESC) AS global_rank
FROM all_facts af
ORDER BY yearly_return_rank, af.total_return_amount DESC
LIMIT 100
