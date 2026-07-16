WITH combined_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           'Catalog' AS channel,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_ext_discount_amt AS discount,
           cs.cs_ext_sales_price AS sales_price,
           cs.cs_ext_tax AS tax,
           cs.cs_net_profit AS profit,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS call_center_sk,
           cs.cs_warehouse_sk AS warehouse_sk,
           cs.cs_bill_customer_sk AS bill_customer_sk,
           cs.cs_ship_customer_sk AS ship_customer_sk,
           cs.cs_ship_addr_sk AS ship_addr_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           'Store',
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_ext_discount_amt,
           ss.ss_ext_sales_price,
           ss.ss_ext_tax,
           ss.ss_net_profit,
           ss.ss_item_sk,
           ss.ss_promo_sk,
           NULL,
           NULL,
           ss.ss_customer_sk,
           ss.ss_customer_sk,
           ss.ss_addr_sk
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           'Web',
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_ext_discount_amt,
           ws.ws_ext_sales_price,
           ws.ws_ext_tax,
           ws.ws_net_profit,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           NULL,
           NULL,
           ws.ws_bill_customer_sk,
           ws.ws_ship_customer_sk,
           ws.ws_ship_addr_sk
    FROM web_sales ws
),
sales_enriched AS (
    SELECT cs.*,
           d.d_year,
           d.d_month_seq,
           i.i_product_name,
           i.i_category,
           i.i_brand,
           p.p_promo_name,
           ca.ca_state AS ship_state,
           cc.cc_name AS call_center_name,
           w.w_warehouse_name
    FROM combined_sales cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
    LEFT JOIN item i ON cs.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca ON cs.ship_addr_sk = ca.ca_address_sk
    LEFT JOIN call_center cc ON cs.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON cs.warehouse_sk = w.w_warehouse_sk
),
monthly_channel_item AS (
    SELECT d_year,
           d_month_seq,
           channel,
           i_category,
           i_brand,
           i_product_name,
           ship_state,
           COUNT(DISTINCT call_center_name) AS distinct_call_centers,
           SUM(sales_price) AS total_sales,
           SUM(profit) AS total_profit,
           SUM(discount) AS total_discount,
           SUM(tax) AS total_tax,
           SUM(quantity) AS total_quantity,
           SUM(net_paid) AS total_net_paid,
           COUNT(*) AS txn_count,
           approx_percentile(net_paid, 0.5) AS median_net_paid,
           SUM(CASE WHEN p_promo_name IS NOT NULL THEN 1 ELSE 0 END) AS promo_txn_count
    FROM sales_enriched
    GROUP BY d_year, d_month_seq, channel, i_category, i_brand, i_product_name, ship_state
),
ranked_items AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY total_sales DESC) AS sales_rank
    FROM monthly_channel_item
)
SELECT d_year,
       d_month_seq,
       channel,
       i_category,
       i_brand,
       i_product_name,
       ship_state,
       total_sales,
       total_profit,
       total_discount,
       total_tax,
       total_quantity,
       total_net_paid,
       txn_count,
       median_net_paid,
       promo_txn_count,
       distinct_call_centers,
       sales_rank
FROM ranked_items
WHERE sales_rank <= 10
ORDER BY d_year, d_month_seq, channel, sales_rank
