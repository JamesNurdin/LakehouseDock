WITH base_refund AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cd_ref.cd_gender AS refunded_gender,
    ca_ref.ca_county AS refunded_county,
    cd_ret.cd_gender AS returning_gender,
    ca_ret.ca_county AS returning_county,
    r.r_reason_desc,
    ws.ws_net_profit,
    ws.ws_ext_tax,
    city_word,
    (SELECT MAX(cr2.cr_return_quantity) FROM catalog_returns cr2 WHERE cr2.cr_return_amount > 1000) AS max_return_qty_over_1000
  FROM catalog_returns cr
  FULL OUTER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  LEFT JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  LEFT JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  LEFT JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  LEFT JOIN web_sales ws
    ON ws.ws_order_number = cr.cr_order_number
  LEFT JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  LEFT JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  CROSS JOIN UNNEST(split(ca_ref.ca_city, ' ')) AS t(city_word)
  WHERE cr.cr_return_amount IS NOT NULL
),

base_highrisk AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cd_ref.cd_gender AS refunded_gender,
    ca_ref.ca_county AS refunded_county,
    cd_ret.cd_gender AS returning_gender,
    ca_ret.ca_county AS returning_county,
    r.r_reason_desc,
    ws.ws_net_profit,
    ws.ws_ext_tax,
    city_word,
    (SELECT MAX(cr2.cr_return_quantity) FROM catalog_returns cr2 WHERE cr2.cr_return_amount > 1000) AS max_return_qty_over_1000
  FROM catalog_returns cr
  FULL OUTER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  LEFT JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  LEFT JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  LEFT JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  LEFT JOIN web_sales ws
    ON ws.ws_order_number = cr.cr_order_number
  LEFT JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  LEFT JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  CROSS JOIN UNNEST(split(ca_ref.ca_city, ' ')) AS t(city_word)
  WHERE cd_ref.cd_credit_rating = 'High Risk'
)

SELECT
  r_reason_desc,
  refunded_county,
  city_word,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(ws_net_profit) AS total_net_profit,
  COUNT(DISTINCT cr_order_number) AS distinct_orders,
  ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS row_num
FROM (
  SELECT * FROM base_refund
  UNION DISTINCT
  SELECT * FROM base_highrisk
) u
GROUP BY
  r_reason_desc,
  refunded_county,
  city_word
ORDER BY total_return_amount DESC
LIMIT 100
