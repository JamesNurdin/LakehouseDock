WITH
  addr_map_cte AS (
    SELECT
      ca_address_sk,
      ca_state,
      map(ARRAY['city','state'], ARRAY[ca_city, ca_state]) AS addr_map
    FROM customer_address
    WHERE ca_state = 'CA'                         -- predicate 1
      AND ca_country = 'United States'           -- predicate 2
      AND ca_zip LIKE '9%'                        -- predicate 3
  ),
  billing_agg AS (
    SELECT
      ws.ws_bill_addr_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_bill_customer_sk,
      ca.ca_state,
      cd.cd_education_status,
      SUM(ws.ws_net_profit)               AS total_profit,
      AVG(ws.ws_ext_discount_amt)         AS avg_discount,
      COUNT(*)                           AS sales_cnt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_wholesale_cost > 20                  -- predicate 4
      AND ws.ws_coupon_amt < 200                    -- predicate 5
      AND cd.cd_gender = 'M'
      AND EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = ws.ws_ship_cdemo_sk
          AND cd2.cd_dep_employed_count > 2
      )
    GROUP BY ws.ws_bill_addr_sk, ws.ws_bill_cdemo_sk, ws.ws_bill_customer_sk, ca.ca_state, cd.cd_education_status
  ),
  shipping_agg AS (
    SELECT
      ws.ws_ship_addr_sk,
      ws.ws_ship_cdemo_sk,
      ws.ws_ship_customer_sk,
      ca.ca_state,
      cd.cd_education_status,
      SUM(ws.ws_net_profit)               AS total_profit,
      AVG(ws.ws_ext_discount_amt)         AS avg_discount,
      COUNT(*)                           AS sales_cnt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_wholesale_cost > 20
      AND ws.ws_coupon_amt < 200
      AND cd.cd_gender = 'M'
      AND EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = ws.ws_bill_cdemo_sk
          AND cd2.cd_dep_employed_count > 2
      )
    GROUP BY ws.ws_ship_addr_sk, ws.ws_ship_cdemo_sk, ws.ws_ship_customer_sk, ca.ca_state, cd.cd_education_status
  ),
  combined AS (
    SELECT
      ba.ws_bill_addr_sk      AS address_sk,
      ba.ws_bill_cdemo_sk,
      ba.ws_bill_customer_sk  AS customer_sk,
      ca.ca_state,
      cd.cd_education_status,
      ba.total_profit,
      ba.avg_discount,
      ba.sales_cnt
    FROM billing_agg ba
    JOIN customer_address ca ON ba.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ba.ws_bill_cdemo_sk = cd.cd_demo_sk
    UNION DISTINCT
    SELECT
      sa.ws_ship_addr_sk       AS address_sk,
      sa.ws_ship_cdemo_sk,
      sa.ws_ship_customer_sk   AS customer_sk,
      ca2.ca_state,
      cd2.cd_education_status,
      sa.total_profit,
      sa.avg_discount,
      sa.sales_cnt
    FROM shipping_agg sa
    JOIN customer_address ca2 ON sa.ws_ship_addr_sk = ca2.ca_address_sk
    JOIN customer_demographics cd2 ON sa.ws_ship_cdemo_sk = cd2.cd_demo_sk
  )
SELECT
  c.address_sk,
  c.ca_state,
  c.cd_education_status,
  c.total_profit,
  c.avg_discount,
  c.sales_cnt,
  (
    SELECT SUM(ws_inner.ws_ext_sales_price)
    FROM web_sales ws_inner
    WHERE ws_inner.ws_bill_customer_sk = c.customer_sk
  )                                           AS total_sales_by_customer,
  um.key,
  um.value
FROM combined c
JOIN addr_map_cte am ON c.address_sk = am.ca_address_sk
CROSS JOIN UNNEST(am.addr_map) AS um(key, value)
WHERE c.total_profit > (
        SELECT AVG(total_profit) FROM combined
      )
  AND c.address_sk IN (
        SELECT ws_sub.ws_bill_addr_sk FROM web_sales ws_sub
        INTERSECT
        SELECT ca_sub.ca_address_sk FROM customer_address ca_sub WHERE ca_sub.ca_zip LIKE '9%'
      )
ORDER BY c.total_profit DESC
LIMIT 100
