SELECT
    d.d_year,
    concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
    regexp_extract(ca.ca_suite_number, '([0-9]+)', 1) AS suite_number,
    sum(sr.sr_net_loss) AS total_loss,
    count(*) AS returns_cnt,
    avg(sr.sr_net_loss) AS avg_loss
FROM tpcds.store_returns AS sr
JOIN tpcds.date_dim AS d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.customer_address AS ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN tpcds.store_sales AS ss
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.call_center AS cc
  ON cc.cc_open_date_sk = d.d_date_sk
WHERE regexp_like(ca.ca_city, '^A')
  AND cc.cc_name LIKE '%Center%'
  AND sr.sr_ticket_number NOT IN (
        SELECT cr.cr_order_number
        FROM tpcds.catalog_returns AS cr
        WHERE cr.cr_return_amount > 5000
      )
GROUP BY d.d_year, ca.ca_city, ca.ca_state, ca.ca_suite_number
HAVING sum(sr.sr_net_loss) > (
        SELECT avg(sr3.sr_net_loss)
        FROM tpcds.store_returns AS sr3
      )
LIMIT 100
