WITH
  cs_pre AS (
    SELECT
      cs_bill_addr_sk,
      SUM(cs_net_paid_inc_ship)      AS sum_net_paid,
      COUNT(*)                       AS cnt_sales,
      AVG(cs_ext_wholesale_cost)     AS avg_wholesale
    FROM catalog_sales
    WHERE cs_quantity > 2
      AND cs_ext_wholesale_cost > 1000
      AND cs_ship_hdemo_sk IN (6203, 2676)
      AND cs_net_paid_inc_ship BETWEEN 500 AND 10000
      AND cs_order_number % 2 = 0
    GROUP BY cs_bill_addr_sk
  ),
  ca_filt AS (
    SELECT
      ca_address_sk,
      ca_state,
      ca_country,
      ca_gmt_offset,
      ca_city,
      ca_county
    FROM customer_address
    WHERE ca_state = 'TX'
      AND ca_country = 'United States'
      AND ca_gmt_offset BETWEEN -6.00 AND -5.00
      AND ca_city LIKE 'A%'
      AND ca_county = 'Perry County'
  ),
  addr_diff AS (
    SELECT cs_bill_addr_sk AS addr_sk
    FROM catalog_sales
    WHERE cs_quantity > 5
    EXCEPT
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_state = 'TX'
  ),
  grp_dim AS (
    SELECT 1 AS grp
    UNION ALL SELECT 2
  ),
  joined AS (
    SELECT
      cs_pre.cs_bill_addr_sk,
      ca_filt.ca_state,
      cs_pre.sum_net_paid,
      cs_pre.cnt_sales,
      cs_pre.avg_wholesale,
      grp_dim.grp
    FROM cs_pre
    FULL OUTER JOIN ca_filt
      ON cs_pre.cs_bill_addr_sk = ca_filt.ca_address_sk
    CROSS JOIN grp_dim
  ),
  lateral_calc AS (
    SELECT
      j.cs_bill_addr_sk,
      j.ca_state,
      j.sum_net_paid,
      j.cnt_sales,
      j.avg_wholesale,
      j.grp,
      CASE
        WHEN j.sum_net_paid > 5000 THEN 'HIGH'
        WHEN j.sum_net_paid > 2000 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS revenue_category,
      lt.state_desc
    FROM joined j
    CROSS JOIN LATERAL (
      SELECT CASE WHEN j.ca_state = 'TX' THEN 'Texas' ELSE 'Other' END AS state_desc
    ) AS lt
  )
SELECT
  lc.revenue_category,
  lc.state_desc,
  lc.grp,
  COUNT(*)                     AS num_addresses,
  SUM(lc.sum_net_paid)         AS total_paid,
  MIN(lc.avg_wholesale)        AS min_avg_wholesale,
  MAX(lc.avg_wholesale)        AS max_avg_wholesale
FROM lateral_calc lc
JOIN addr_diff ad ON lc.cs_bill_addr_sk = ad.addr_sk
WHERE lc.grp = 1
GROUP BY CUBE (lc.revenue_category, lc.state_desc, lc.grp)
ORDER BY total_paid DESC
LIMIT 100
