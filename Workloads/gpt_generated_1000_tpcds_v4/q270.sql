WITH sales_agg AS (
  SELECT
    cp.cp_department AS department,
    ca.ca_county AS county,
    hd.hd_buy_potential AS buy_potential,
    'sales' AS metric_type,
    SUM(cs.cs_ext_sales_price) AS total_amount,
    AVG(cs.cs_sales_price) AS avg_metric,
    COUNT(*) AS cnt,
    MIN(cs.cs_sold_date_sk) AS first_date_sk,
    MAX(cs.cs_sold_date_sk) AS last_date_sk
  FROM tpcds.catalog_sales cs
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  WHERE
    hd.hd_buy_potential = '1001-5000'
    AND ca.ca_county = 'Chelan County'
    AND cp.cp_department = 'Sports'
    AND cp.cp_catalog_number = 5
  GROUP BY
    cp.cp_department,
    ca.ca_county,
    hd.hd_buy_potential
),
returns_agg AS (
  SELECT
    cp.cp_department AS department,
    ca.ca_county AS county,
    hd.hd_buy_potential AS buy_potential,
    'returns' AS metric_type,
    SUM(cr.cr_return_amount) AS total_amount,
    AVG(CAST(cr.cr_return_quantity AS double)) AS avg_metric,
    COUNT(*) AS cnt,
    MIN(cr.cr_returned_date_sk) AS first_date_sk,
    MAX(cr.cr_returned_date_sk) AS last_date_sk
  FROM tpcds.catalog_returns cr
  JOIN tpcds.catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
  JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE
    hd.hd_buy_potential = '1001-5000'
    AND ca.ca_county = 'Chelan County'
    AND cp.cp_department = 'Sports'
    AND cp.cp_catalog_number = 5
  GROUP BY
    cp.cp_department,
    ca.ca_county,
    hd.hd_buy_potential
)
SELECT *
FROM (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM returns_agg
) combined
ORDER BY total_amount DESC
LIMIT 100
