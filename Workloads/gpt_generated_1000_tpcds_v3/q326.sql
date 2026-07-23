WITH returns_agg AS (
  SELECT
    ca.ca_state,
    ca.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    'return' AS record_type,
    COUNT(DISTINCT cr.cr_order_number) AS order_cnt,
    SUM(cr.cr_return_amount) AS metric_1,
    SUM(cr.cr_net_loss) AS metric_2,
    AVG(cr.cr_return_quantity) AS metric_3,
    MIN(cr.cr_return_amount) AS metric_4,
    MAX(cr.cr_return_amount) AS metric_5
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE ca.ca_state = 'TX'
    AND ca.ca_county = 'Oldham County'
    AND ca.ca_location_type = 'apartment'
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    AND cr.cr_return_quantity > 0
  GROUP BY ca.ca_state, ca.ca_city, cd.cd_gender, cd.cd_marital_status
),
sales_agg AS (
  SELECT
    ca.ca_state,
    ca.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    'sale' AS record_type,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS metric_1,
    SUM(cs.cs_net_profit) AS metric_2,
    AVG(cs.cs_quantity) AS metric_3,
    MIN(cs.cs_sales_price) AS metric_4,
    MAX(cs.cs_sales_price) AS metric_5
  FROM catalog_sales cs
  LEFT JOIN catalog_returns cr
    ON cs.cs_item_sk = cr.cr_item_sk
   AND cs.cs_order_number = cr.cr_order_number
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ca.ca_state = 'TX'
    AND ca.ca_county = 'Oldham County'
    AND ca.ca_location_type = 'single family'
    AND cd.cd_gender = 'M'
    AND cd.cd_marital_status = 'S'
    AND cs.cs_ext_list_price > 3000.00
  GROUP BY ca.ca_state, ca.ca_city, cd.cd_gender, cd.cd_marital_status
)
SELECT *
FROM returns_agg
UNION ALL
SELECT *
FROM sales_agg
ORDER BY ca_state, ca_city, record_type
