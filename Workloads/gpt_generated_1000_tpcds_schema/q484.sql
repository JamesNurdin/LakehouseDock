WITH store_loss AS (
   SELECT
       regexp_extract(ca.ca_county, '(\\w+) County', 1) AS county_base,
       i.i_brand AS i_brand,
       SUM(sr.sr_net_loss) AS total_store_loss,
       COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
       SUM(DISTINCT sr.sr_return_amt) AS distinct_return_amount,
       (
           SELECT SUM(cr.cr_return_amount)
           FROM catalog_returns cr
           WHERE cr.cr_item_sk = i.i_item_sk
       ) AS total_catalog_return_amount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE regexp_like(ca.ca_county, 'County')
     AND ca.ca_city LIKE 'M%'
     AND EXISTS (
         SELECT 1
         FROM call_center cc
         WHERE cc.cc_closed_date_sk = d.d_date_sk
           AND cc.cc_state = ca.ca_state
     )
   GROUP BY regexp_extract(ca.ca_county, '(\\w+) County', 1), i.i_brand, i.i_item_sk
),
store_loss_alt AS (
   SELECT
       regexp_extract(ca.ca_county, '(\\w+) County', 1) AS county_base,
       i.i_brand AS i_brand,
       SUM(sr.sr_net_loss) AS total_store_loss,
       COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
       SUM(DISTINCT sr.sr_return_amt) AS distinct_return_amount,
       (
           SELECT SUM(cr.cr_return_amount)
           FROM catalog_returns cr
           WHERE cr.cr_item_sk = i.i_item_sk
       ) AS total_catalog_return_amount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE substring(ca.ca_suite_number, 1, 5) = 'Suite'
     AND ca.ca_zip LIKE '9%'
     AND EXISTS (
         SELECT 1
         FROM call_center cc
         WHERE cc.cc_open_date_sk = d.d_date_sk
           AND cc.cc_state = ca.ca_state
     )
   GROUP BY regexp_extract(ca.ca_county, '(\\w+) County', 1), i.i_brand, i.i_item_sk
)
SELECT
    sl.county_base,
    sl.i_brand,
    sl.total_store_loss,
    sl.distinct_customers,
    sl.distinct_return_amount,
    sl.total_catalog_return_amount
FROM store_loss sl
INTERSECT
SELECT
    sla.county_base,
    sla.i_brand,
    sla.total_store_loss,
    sla.distinct_customers,
    sla.distinct_return_amount,
    sla.total_catalog_return_amount
FROM store_loss_alt sla
ORDER BY total_store_loss DESC
LIMIT 100
