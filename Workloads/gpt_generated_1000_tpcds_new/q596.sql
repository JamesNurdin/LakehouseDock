WITH ws_sample AS (
   SELECT *
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE ws_quantity > 0
),

enriched AS (
   SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_warehouse_sk,
      ws.ws_web_site_sk,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      i.i_category_id,
      t.t_sub_shift,
      ca.ca_state,
      w.w_warehouse_name,
      w.w_state,
      w.w_gmt_offset,
      s.web_state,
      cd.cd_demo_sk,
      cd.cd_credit_rating,
      calc.ten_percent_sales
   FROM ws_sample ws
   INNER JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
   INNER JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   INNER JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
   INNER JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   CROSS JOIN LATERAL (
        SELECT ws.ws_ext_sales_price * 0.1 AS ten_percent_sales
   ) AS calc
   WHERE
       i.i_category_id IN (1, 2, 4)
       AND w.w_gmt_offset = -6.00
       AND t.t_sub_shift = 'morning'
       AND ca.ca_state = 'CA'
       AND s.web_state = 'CA'
       AND i.i_rec_start_date >= DATE '2000-01-01'
       AND cd.cd_credit_rating = 'AA'
),

high_price_items AS (
   SELECT i.i_item_sk
   FROM item i
   WHERE i.i_current_price > 1000
),

low_price_items AS (
   SELECT i.i_item_sk
   FROM item i
   WHERE i.i_current_price < 100
),

filtered_items AS (
   SELECT i_item_sk FROM high_price_items
   EXCEPT
   SELECT i_item_sk FROM low_price_items
)

SELECT *
FROM (
   SELECT
       e.w_warehouse_name AS entity_name,
       e.w_state AS location,
       CASE WHEN e.w_gmt_offset < -5 THEN 'West' ELSE 'Other' END AS region,
       SUM(e.ws_net_profit) AS total_profit,
       AVG(e.ws_net_profit) AS avg_profit,
       RANK() OVER (PARTITION BY e.w_state ORDER BY SUM(e.ws_net_profit) DESC) AS profit_rank_state,
       COUNT(DISTINCT e.ws_order_number) AS orders_cnt,
       (SELECT AVG(i2.i_current_price)
          FROM item i2
         WHERE i2.i_category_id = e.i_category_id) AS avg_price_by_category
   FROM enriched e
   WHERE e.ws_item_sk IN (SELECT i_item_sk FROM filtered_items)
   GROUP BY e.w_warehouse_name, e.w_state, e.w_gmt_offset, e.i_category_id

   UNION DISTINCT

   SELECT
       i.i_brand AS entity_name,
       i.i_category AS location,
       CASE WHEN w.w_gmt_offset < -5 THEN 'West' ELSE 'Other' END AS region,
       SUM(e.ws_net_profit) AS total_profit,
       AVG(e.ws_net_profit) AS avg_profit,
       DENSE_RANK() OVER (ORDER BY SUM(e.ws_net_profit) DESC) AS profit_rank_state,
       COUNT(DISTINCT e.ws_order_number) AS orders_cnt,
       (SELECT AVG(i2.i_current_price)
          FROM item i2
         WHERE i2.i_category_id = i.i_category_id) AS avg_price_by_category
   FROM enriched e
   INNER JOIN item i ON e.ws_item_sk = i.i_item_sk
   INNER JOIN warehouse w ON e.ws_warehouse_sk = w.w_warehouse_sk
   WHERE EXISTS (
       SELECT 1
         FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = e.cd_demo_sk
          AND cd2.cd_education_status = 'College'
   )
   GROUP BY i.i_brand, i.i_category, w.w_gmt_offset, i.i_category_id
) final_result
ORDER BY total_profit DESC
LIMIT 100
