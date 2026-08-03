WITH base AS (
   SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_category,
      i.i_current_price,
      ca.ca_state,
      cd.cd_gender,
      ws.ws_net_profit,
      ws.ws_quantity,
      ws.ws_sales_price,
      ws.ws_ext_sales_price,
      ws.ws_ext_discount_amt,
      wsit.web_site_id,
      s.s_store_id,
      CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_desc,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_profit DESC) AS rn_year,
      RANK() OVER (ORDER BY ws.ws_ext_sales_price DESC) AS rnk_global,
      (SELECT MAX(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk = d.d_date_sk) AS max_price_on_date
   FROM web_sales ws
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
     ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
   JOIN web_site wsit
     ON ws.ws_web_site_sk = wsit.web_site_sk
   JOIN store s
     ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_category_id IN (5, 10)
     AND wsit.web_state = 'CA'
     AND ws.ws_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_current_price > 20)
),
unioned AS (
   SELECT ws_order_number, d_year, i_item_id, gender_desc, ws_net_profit, rn_year, rnk_global, max_price_on_date
   FROM base
   WHERE rn_year <= 5
   UNION
   SELECT ws_order_number, d_year, i_item_id, gender_desc, ws_net_profit, rn_year, rnk_global, max_price_on_date
   FROM base
   WHERE ws_net_profit > 0
)
SELECT
   ws_order_number,
   d_year,
   i_item_id,
   gender_desc,
   ws_net_profit,
   rn_year,
   rnk_global,
   max_price_on_date
FROM unioned
ORDER BY d_year DESC, ws_net_profit DESC
LIMIT 100
