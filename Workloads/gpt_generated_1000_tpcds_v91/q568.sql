SELECT
    c.c_customer_id AS customer_id,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    cs.cs_net_paid AS net_amount,
    trim(street_num) AS street_number,
    (SELECT COUNT(DISTINCT cs2.cs_item_sk)
     FROM catalog_sales cs2
     WHERE cs2.cs_bill_customer_sk = c.c_customer_sk) AS distinct_items,
    'catalog' AS source
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
CROSS JOIN UNNEST(split(ca.ca_street_number, ',')) AS t(street_num)
WHERE d.d_year = 2000
  AND p.p_channel_catalog = 'Y'
  AND ca.ca_country = 'United States'
  AND cs.cs_net_paid > 0

UNION

SELECT
    c.c_customer_id AS customer_id,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    sr.sr_net_loss AS net_amount,
    trim(street_num) AS street_number,
    (SELECT COUNT(DISTINCT sr2.sr_item_sk)
     FROM store_returns sr2
     WHERE sr2.sr_customer_sk = c.c_customer_sk) AS distinct_items,
    'store_return' AS source
FROM store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
CROSS JOIN UNNEST(split(ca.ca_street_number, ',')) AS t(street_num)
WHERE d.d_year = 2000
  AND ca.ca_country = 'United States'
  AND sr.sr_net_loss > 0

ORDER BY net_amount DESC
LIMIT 100
