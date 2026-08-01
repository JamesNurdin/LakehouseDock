WITH src AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cd.cd_credit_rating,
        cd.cd_gender,
        sm.sm_carrier,
        sm.sm_contract,
        d_sold.d_year,
        regexp_extract(sm.sm_contract, '^([A-Za-z]+)', 1) AS contract_prefix,
        CASE WHEN regexp_like(sm.sm_contract, '\\d') THEN true ELSE false END AS contract_has_digit,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = cs.cs_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
)
SELECT
    src.sm_carrier,
    src.contract_prefix,
    src.d_year,
    CONCAT(src.sm_carrier, '_', src.contract_prefix) AS carrier_contract_label,
    COUNT(DISTINCT src.cs_bill_customer_sk) AS distinct_customers,
    SUM(src.cs_net_profit) AS total_profit,
    AVG(src.cs_net_paid_inc_ship_tax) AS avg_paid_inc_ship_tax,
    AVG(src.inv_quantity_on_hand) AS avg_inventory_quantity,
    COUNT(*) AS total_orders
FROM src
WHERE
    src.d_year BETWEEN 1998 AND 1999
    AND regexp_like(src.cd_credit_rating, '^High')
    AND src.sm_carrier LIKE 'D%'
    AND src.contract_has_digit = true
GROUP BY
    src.sm_carrier,
    src.contract_prefix,
    src.d_year
ORDER BY total_profit DESC
LIMIT 100
