WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ship_mode_sk,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_carrier,
        sm.sm_contract
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ext_ship_cost > 500
      AND cs.cs_ext_ship_cost < 3000
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND sm.sm_code IN ('AIR', 'SEA')
      AND sm.sm_carrier <> 'MSC'
),
filtered_ship AS (
    SELECT
        sm_ship_mode_sk,
        sm_ship_mode_id,
        sm_code,
        sm_carrier,
        sm_contract
    FROM ship_mode
    WHERE sm_contract LIKE 'P7%'
),
full_joined AS (
    SELECT
        b.cs_order_number,
        b.cs_ship_mode_sk,
        b.cs_ext_ship_cost,
        b.cs_net_paid_inc_tax,
        b.cs_net_paid_inc_ship,
        b.cs_quantity,
        b.sm_ship_mode_id,
        b.sm_code,
        b.sm_carrier,
        b.sm_contract,
        fs.sm_ship_mode_sk   AS fs_ship_mode_sk,
        fs.sm_ship_mode_id   AS fs_ship_mode_id,
        fs.sm_code           AS fs_code,
        fs.sm_carrier        AS fs_carrier,
        fs.sm_contract       AS fs_contract
    FROM filtered_ship fs
    FULL OUTER JOIN base b
        ON fs.sm_ship_mode_sk = b.cs_ship_mode_sk
),
ranked AS (
    SELECT
        cs_order_number,
        cs_ship_mode_sk,
        cs_ext_ship_cost,
        cs_net_paid_inc_tax,
        cs_net_paid_inc_ship,
        cs_quantity,
        sm_ship_mode_id,
        sm_code,
        sm_carrier,
        sm_contract,
        ROW_NUMBER() OVER (PARTITION BY sm_code ORDER BY cs_net_paid_inc_tax DESC) AS rn,
        RANK() OVER (ORDER BY cs_net_paid_inc_tax DESC) AS overall_rank
    FROM full_joined
    WHERE cs_order_number IS NOT NULL
)
SELECT
    cs_order_number,
    cs_ship_mode_sk,
    cs_ext_ship_cost,
    cs_net_paid_inc_tax,
    cs_net_paid_inc_ship,
    cs_quantity,
    sm_ship_mode_id,
    sm_code,
    sm_carrier,
    sm_contract,
    rn,
    overall_rank
FROM ranked
WHERE cs_order_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_ship_cost > 2500
    )
  AND (cs_order_number, sm_code) IN (
        SELECT cs_order_number, sm_code
        FROM ranked
        WHERE cs_quantity >= 5
        INTERSECT
        SELECT cs_order_number, sm_code
        FROM ranked
        WHERE cs_ext_ship_cost BETWEEN 600 AND 2000
    )
ORDER BY overall_rank
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
