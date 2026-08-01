WITH sales_by_ship AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_code,
        d.d_year,
        sm.sm_contract,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count,
        AVG(cs.cs_quantity) AS avg_quantity,
        REGEXP_EXTRACT(sm.sm_contract, '([A-Za-z]{3})') AS contract_prefix
    FROM
        catalog_sales cs
        INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND sm.sm_ship_mode_id LIKE 'AAAAAAA%'
        AND REGEXP_LIKE(sm.sm_contract, '^.{3}[0-9]$')
    GROUP BY
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_code,
        d.d_year,
        sm.sm_contract
)
SELECT
    sb.sm_ship_mode_id,
    sb.sm_code,
    sb.d_year,
    sb.total_net_profit,
    sb.orders_count,
    sb.avg_quantity,
    sb.contract_prefix,
    CONCAT(sb.sm_ship_mode_id, '-', sb.sm_code) AS ship_mode_concat,
    SUBSTR(sb.sm_ship_mode_id, 1, 5) AS ship_mode_prefix,
    LOWER(sb.sm_code) AS sm_code_lower,
    (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        INNER JOIN item i ON inv.inv_item_sk = i.i_item_sk
        INNER JOIN catalog_sales cs2 ON cs2.cs_item_sk = i.i_item_sk
        INNER JOIN ship_mode sm2 ON cs2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
        WHERE sm2.sm_ship_mode_sk = sb.sm_ship_mode_sk
    ) AS total_inventory_quantity,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_sales cs3
            INNER JOIN customer cust ON cs3.cs_bill_customer_sk = cust.c_customer_sk
            INNER JOIN customer_demographics cd ON cust.c_current_cdemo_sk = cd.cd_demo_sk
            WHERE cs3.cs_ship_mode_sk = sb.sm_ship_mode_sk
              AND cd.cd_credit_rating = 'Excellent'
              AND cd.cd_education_status LIKE '%College%'
              AND cs3.cs_net_paid > 1000
        ) THEN 'YES' ELSE 'NO'
    END AS has_excellent_college_customer
FROM
    sales_by_ship sb
ORDER BY
    sb.total_net_profit DESC
LIMIT 100
