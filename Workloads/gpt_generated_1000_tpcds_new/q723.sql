WITH sampled_addresses AS (
    SELECT ca_address_sk, ca_city, ca_state
    FROM tpcds.customer_address
    TABLESAMPLE BERNOULLI (10)
)
SELECT order_id, net_amount
FROM (
    /* Intersect web_sales and catalog_returns orders that share sampled addresses */
    SELECT ws_order_number AS order_id,
           ws_net_paid_inc_ship_tax AS net_amount
    FROM tpcds.web_sales ws
    JOIN sampled_addresses sa
      ON ws.ws_bill_addr_sk = sa.ca_address_sk
    WHERE ws.ws_list_price > (
              SELECT MAX(cr_return_amount)
              FROM tpcds.catalog_returns
          )
    INTERSECT
    SELECT cr_order_number AS order_id,
           cr_net_loss AS net_amount
    FROM tpcds.catalog_returns cr
    JOIN sampled_addresses sa
      ON cr.cr_refunded_addr_sk = sa.ca_address_sk
    WHERE cr.cr_return_amount > 500
) AS intersected
UNION ALL
SELECT order_id, net_amount
FROM (
    /* Orders from web_sales that ship to condo addresses, minus store returns meeting a quantity filter */
    SELECT ws.ws_order_number AS order_id,
           ws.ws_net_paid_inc_ship_tax AS net_amount
    FROM tpcds.web_sales ws
    JOIN sampled_addresses sa
      ON ws.ws_ship_addr_sk = sa.ca_address_sk
    WHERE ws.ws_ship_addr_sk IN (
              SELECT ca_address_sk
              FROM tpcds.customer_address
              WHERE ca_location_type = 'condo'
          )
    EXCEPT
    SELECT sr.sr_ticket_number AS order_id,
           sr.sr_net_loss AS net_amount
    FROM tpcds.store_returns sr
    JOIN sampled_addresses sa
      ON sr.sr_addr_sk = sa.ca_address_sk
    WHERE sr.sr_return_quantity > 5
) AS excepted
ORDER BY order_id DESC
OFFSET 20
LIMIT 100
