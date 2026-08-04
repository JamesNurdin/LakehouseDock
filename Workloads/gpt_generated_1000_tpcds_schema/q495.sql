WITH sampled_sales AS (
    SELECT
        cs_ship_mode_sk,
        cs_quantity,
        cs_wholesale_cost,
        cs_ext_tax,
        cs_ext_list_price,
        cs_ship_date_sk,
        cs_ext_sales_price,
        cs_net_profit,
        cs_order_number,
        cs_net_paid_inc_ship
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
agg1 AS (
    SELECT
        cs_ship_mode_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*) AS cnt,
        AVG(cs_net_profit) AS avg_profit
    FROM sampled_sales
    WHERE cs_quantity > 5
      AND cs_wholesale_cost BETWEEN 100 AND 5000
      AND cs_ext_tax < 500
      AND cs_ext_list_price > 1000
      AND cs_ship_date_sk IS NOT NULL
    GROUP BY cs_ship_mode_sk
),
joined AS (
    SELECT
        a.cs_ship_mode_sk,
        a.total_sales,
        a.cnt,
        a.avg_profit,
        sm.sm_carrier,
        sm.sm_code
    FROM agg1 a
    JOIN ship_mode sm
      ON a.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
agg2 AS (
    SELECT
        sm_carrier,
        SUM(total_sales) AS carrier_sales,
        AVG(avg_profit) AS carrier_avg_profit
    FROM joined
    GROUP BY sm_carrier
    HAVING SUM(total_sales) > 10000
),
keys_c AS (
    SELECT cs_ship_mode_sk FROM catalog_sales WHERE cs_quantity BETWEEN 1 AND 3
),
keys_d AS (
    SELECT cs_ship_mode_sk FROM catalog_sales WHERE cs_ext_tax > 100
),
intersect_ship_keys AS (
    SELECT cs_ship_mode_sk FROM keys_c
    INTERSECT
    SELECT cs_ship_mode_sk FROM keys_d
),
except_ship_keys AS (
    SELECT cs_ship_mode_sk FROM keys_c
    EXCEPT
    SELECT cs_ship_mode_sk FROM keys_d
),
anti_keys AS (
    SELECT cs_ship_mode_sk FROM catalog_sales WHERE cs_net_paid_inc_ship < 2000
),
full_joined AS (
    SELECT
        j.cs_ship_mode_sk,
        j.sm_carrier,
        j.sm_code,
        j.total_sales,
        j.cnt,
        j.avg_profit
    FROM joined j
    FULL OUTER JOIN agg2 a2
      ON j.sm_carrier = a2.sm_carrier
)
SELECT
    fj.sm_carrier,
    fj.sm_code,
    fj.total_sales,
    fj.cnt,
    fj.avg_profit
FROM full_joined fj
WHERE fj.cs_ship_mode_sk NOT IN (SELECT cs_ship_mode_sk FROM anti_keys)
  AND fj.cs_ship_mode_sk IN (SELECT cs_ship_mode_sk FROM intersect_ship_keys)
  AND fj.cs_ship_mode_sk NOT IN (SELECT cs_ship_mode_sk FROM except_ship_keys)
ORDER BY fj.total_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
