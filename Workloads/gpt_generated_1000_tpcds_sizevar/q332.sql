WITH cs_base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_ext_list_price,
    cs.cs_ext_ship_cost,
    cs.cs_quantity,
    cs.cs_bill_cdemo_sk,
    cs.cs_bill_addr_sk,
    cd1.cd_demo_sk,
    cd1.cd_gender,
    cd1.cd_marital_status,
    ca1.ca_state,
    ca1.ca_city,
    ca1.ca_location_type
  FROM catalog_sales cs
  LEFT JOIN customer_demographics cd1
    ON cs.cs_bill_cdemo_sk = cd1.cd_demo_sk
  LEFT JOIN customer_address ca1
    ON cs.cs_bill_addr_sk = ca1.ca_address_sk
  WHERE cs.cs_ext_list_price > 1000
    AND cs.cs_ext_ship_cost < 2000
    AND ca1.ca_state = 'TX'
    AND cd1.cd_gender = 'M'
),
ss_base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_net_paid,
    ss.ss_quantity,
    ss.ss_cdemo_sk,
    ss.ss_addr_sk,
    cd2.cd_demo_sk AS ss_cd_demo_sk,
    cd2.cd_gender AS ss_cd_gender,
    ca2.ca_location_type,
    ca2.ca_state AS ss_state
  FROM store_sales ss
  LEFT JOIN customer_demographics cd2
    ON ss.ss_cdemo_sk = cd2.cd_demo_sk
  LEFT JOIN customer_address ca2
    ON ss.ss_addr_sk = ca2.ca_address_sk
  WHERE ss.ss_net_paid >= 2000
    AND ca2.ca_location_type = 'apartment'
)
SELECT
  COALESCE(cs.cd_demo_sk, ss.ss_cd_demo_sk) AS demo_sk,
  COALESCE(cs.cd_gender, ss.ss_cd_gender) AS gender,
  cs.ca_city,
  cs.ca_state,
  ss.ss_state,
  cs.cs_ext_list_price,
  ss.ss_net_paid,
  qty,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(cs.cd_demo_sk, ss.ss_cd_demo_sk) ORDER BY cs.cs_ext_list_price DESC) AS rn_by_demo,
  ROW_NUMBER() OVER (ORDER BY cs.cs_ext_list_price DESC) AS global_rn
FROM cs_base cs
FULL OUTER JOIN ss_base ss
  ON cs.cd_demo_sk = ss.ss_cd_demo_sk
CROSS JOIN UNNEST(ARRAY[cs.cs_quantity, ss.ss_quantity]) AS t(qty)
WHERE cs.cs_ext_list_price IS NOT NULL OR ss.ss_net_paid IS NOT NULL
ORDER BY global_rn
LIMIT 100
