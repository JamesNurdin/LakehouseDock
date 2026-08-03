WITH filtered_returns AS (
  SELECT
    cr.cr_returning_addr_sk,
    cr.cr_refunded_addr_sk,
    cr.cr_returning_hdemo_sk,
    cr.cr_refunded_hdemo_sk,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_store_credit,
    cr.cr_item_sk,
    cr.cr_returned_date_sk,
    cr.cr_return_quantity
  FROM catalog_returns cr
  WHERE cr.cr_return_amount > 100
    AND cr.cr_store_credit < 2000
    AND cr.cr_return_tax BETWEEN 1 AND 150
),
first_part AS (
  SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    hd.hd_buy_potential,
    fr.cr_return_amount,
    fr.cr_return_tax,
    fr.cr_store_credit,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY fr.cr_return_amount DESC) AS rn_state,
    CASE WHEN fr.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_refunded_addr_sk = ca.ca_address_sk) AS refunded_return_cnt
  FROM filtered_returns fr
  JOIN customer_address ca
    ON fr.cr_returning_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON fr.cr_returning_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_dep_count >= 2
    AND hd.hd_vehicle_count <> -1
    AND ca.ca_state IN ('CA','TX','NY')
),
second_part AS (
  SELECT
    ca2.ca_address_id,
    ca2.ca_city,
    ca2.ca_state,
    hd2.hd_buy_potential,
    fr2.cr_return_amount,
    fr2.cr_return_tax,
    fr2.cr_store_credit,
    ROW_NUMBER() OVER (PARTITION BY ca2.ca_state ORDER BY fr2.cr_return_amount DESC) AS rn_state,
    CASE WHEN fr2.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    (SELECT COUNT(*) FROM catalog_returns cr3 WHERE cr3.cr_refunded_addr_sk = ca2.ca_address_sk) AS refunded_return_cnt
  FROM filtered_returns fr2
  JOIN customer_address ca2
    ON fr2.cr_refunded_addr_sk = ca2.ca_address_sk
  JOIN household_demographics hd2
    ON fr2.cr_refunded_hdemo_sk = hd2.hd_demo_sk
  WHERE hd2.hd_dep_count <= 3
    AND hd2.hd_vehicle_count >= 0
    AND ca2.ca_state NOT IN ('CA','TX','NY')
)
SELECT *
FROM (
  SELECT * FROM first_part
  UNION DISTINCT
  SELECT * FROM second_part
) AS combined
ORDER BY amount_category DESC, rn_state
OFFSET 0
LIMIT 100
