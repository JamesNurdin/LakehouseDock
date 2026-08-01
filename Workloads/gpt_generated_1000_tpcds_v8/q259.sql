/* Goal: Identify household demographic groups with strong sales performance, using string pattern filters on the demographic buying‑potential field, joining to store sales, applying window functions, and combining results via UNION and INTERSECT. */
WITH
-- First set: demographic rows that match two different string patterns (union removes duplicates)
union_demo AS (
    SELECT hd_demo_sk,
           hd_buy_potential
    FROM   household_demographics
    WHERE  regexp_like(hd_buy_potential, '^A[0-9]{2}$')
    UNION
    SELECT hd_demo_sk,
           hd_buy_potential
    FROM   household_demographics
    WHERE  hd_buy_potential LIKE 'B_%'
),
-- Second set: keys that appear in both a high‑coupon sales slice and a vehicle‑count slice (intersect)
intersect_keys AS (
    SELECT ss_hdemo_sk AS hd_demo_sk
    FROM   store_sales
    WHERE  ss_coupon_amt > 1000
    INTERSECT
    SELECT hd_demo_sk
    FROM   household_demographics
    WHERE  hd_vehicle_count >= 2
),
-- Join the unions with sales, keep only households that are also in the intersect set, aggregate and rank
joined_sales AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        COUNT(ss.ss_ticket_number)                           AS sales_cnt,
        SUM(ss.ss_net_profit)                                 AS total_profit,
        ROW_NUMBER() OVER (
            PARTITION BY hd.hd_demo_sk
            ORDER BY SUM(ss.ss_net_profit) DESC
        )                                                    AS rn
    FROM   union_demo u
    JOIN   household_demographics hd
           ON u.hd_demo_sk = hd.hd_demo_sk
    JOIN   store_sales ss
           ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE  hd.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_keys)
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_buy_potential
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    hd_demo_sk,
    hd_buy_potential,
    sales_cnt,
    total_profit,
    -- Extract numeric part of buy potential (e.g., 'A12' → '12')
    regexp_extract(hd_buy_potential, '[0-9]+')               AS buy_potential_digits,
    -- Concatenate a readable identifier
    concat('Demo-', CAST(hd_demo_sk AS VARCHAR))            AS demo_id
FROM   joined_sales
WHERE  rn = 1
ORDER BY total_profit DESC
LIMIT 100
