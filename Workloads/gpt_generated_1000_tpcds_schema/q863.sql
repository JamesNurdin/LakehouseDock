WITH
  bill_agg AS (
    SELECT
      ca.ca_address_id,
      ca.ca_city,
      hd.hd_income_band_sk,
      SUM(cs.cs_net_profit) AS total_profit,
      AVG(cs.cs_coupon_amt) AS avg_coupon,
      COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_ext_wholesale_cost < 5000
      AND cs.cs_coupon_amt BETWEEN 0 AND 1000
      AND hd.hd_dep_count >= 1
      AND hd.hd_dep_count <= 8
      AND ca.ca_state = 'CA'
      AND cs.cs_net_paid > 0
    GROUP BY ca.ca_address_id, ca.ca_city, hd.hd_income_band_sk
  ),
  ship_agg AS (
    SELECT
      ca.ca_address_id,
      ca.ca_city,
      hd.hd_income_band_sk,
      SUM(cs.cs_net_profit) AS total_profit,
      AVG(cs.cs_coupon_amt) AS avg_coupon,
      COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_ext_wholesale_cost < 5000
      AND cs.cs_coupon_amt BETWEEN 0 AND 1000
      AND hd.hd_dep_count >= 1
      AND hd.hd_dep_count <= 8
      AND ca.ca_state = 'CA'
      AND cs.cs_net_paid > 0
    GROUP BY ca.ca_address_id, ca.ca_city, hd.hd_income_band_sk
  ),
  bill_filt AS (
    SELECT *
    FROM bill_agg
    WHERE total_profit > 10000
      AND avg_coupon > 50
      AND txn_cnt >= 5
  ),
  ship_filt AS (
    SELECT *
    FROM ship_agg
    WHERE total_profit > 10000
      AND avg_coupon > 50
      AND txn_cnt >= 5
  )
SELECT address_id, total_profit
FROM (
  SELECT bf.ca_address_id AS address_id, bf.total_profit
  FROM bill_filt bf
  WHERE bf.ca_address_id NOT IN (
    SELECT ca_address_id
    FROM customer_address
    WHERE ca_zip LIKE '9%'
  )
  UNION
  SELECT sf.ca_address_id AS address_id, sf.total_profit
  FROM ship_filt sf
  WHERE sf.ca_address_id NOT IN (
    SELECT ca_address_id
    FROM customer_address
    WHERE ca_zip LIKE '9%'
  )
) AS combined
EXCEPT
SELECT bf.ca_address_id, bf.total_profit
FROM bill_filt bf
WHERE bf.total_profit < 20000
INTERSECT
SELECT sf.ca_address_id, sf.total_profit
FROM ship_filt sf
WHERE sf.txn_cnt > 10
ORDER BY total_profit DESC
LIMIT 100
