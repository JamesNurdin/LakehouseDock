WITH
  diff_keys AS (
    SELECT cs_ship_mode_sk
    FROM catalog_sales
    WHERE cs_coupon_amt > 250
    EXCEPT
    SELECT sm_ship_mode_sk
    FROM ship_mode
    WHERE sm_type = 'REGULAR'
  ),
  base_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ship_mode_sk,
      cs.cs_ship_date_sk,
      cs.cs_coupon_amt,
      cs.cs_ext_sales_price,
      cs.cs_quantity,
      cs.cs_list_price,
      cs.cs_ext_discount_amt,
      sm.sm_ship_mode_id,
      sm.sm_type,
      sm.sm_carrier
    FROM catalog_sales cs
    FULL OUTER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
      cs.cs_ship_date_sk BETWEEN 2450830 AND 2450900
      AND cs.cs_coupon_amt > 100
      AND sm.sm_type = 'EXPRESS'
  ),
  enriched AS (
    SELECT
      bj.*, 
      lt.line_total,
      CASE
        WHEN bj.cs_ext_sales_price > (
          SELECT MAX(cs_ext_sales_price)
          FROM catalog_sales
          WHERE cs_ship_mode_sk = 5
        ) THEN 'HIGH'
        ELSE 'NORMAL'
      END AS price_category
    FROM base_join bj
    CROSS JOIN LATERAL (
      SELECT bj.cs_quantity * bj.cs_list_price AS line_total
    ) lt
    WHERE EXISTS (
      SELECT 1
      FROM catalog_sales cs2
      WHERE cs2.cs_order_number = bj.cs_order_number
        AND cs2.cs_ext_discount_amt > 0
    )
    AND bj.cs_ship_mode_sk IN (SELECT cs_ship_mode_sk FROM diff_keys)
  )
SELECT
  sm_ship_mode_id,
  sm_type,
  sm_carrier,
  price_category,
  SUM(cs_ext_sales_price) AS total_sales,
  COUNT(*) AS order_cnt,
  SUM(line_total) AS total_line_amount,
  RANK() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
FROM enriched
GROUP BY
  sm_ship_mode_id,
  sm_type,
  sm_carrier,
  price_category
ORDER BY sales_rank
LIMIT 100
