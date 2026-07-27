WITH sales_by_mode AS (
    SELECT
        sm.sm_type AS sm_type,
        sm.sm_contract AS sm_contract,
        CASE
            WHEN cs.cs_quantity >= 10 THEN 'Bulk'
            ELSE 'Standard'
        END AS order_category,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS order_cnt,
        AVG(cs.cs_net_paid_inc_ship) AS avg_net_paid
    FROM tpcds.catalog_sales cs
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        cs.cs_quantity BETWEEN 1 AND 20
        AND cs.cs_net_paid_inc_ship > 1000
        AND cs.cs_ship_addr_sk IN (4818292, 648956, 3915244)
        AND cs.cs_bill_cdemo_sk > 50000
        AND sm.sm_type IN ('REGULAR', 'EXPRESS', 'NEXT DAY')
        AND sm.sm_contract LIKE 'I3uCel%'
    GROUP BY
        sm.sm_type,
        sm.sm_contract,
        CASE
            WHEN cs.cs_quantity >= 10 THEN 'Bulk'
            ELSE 'Standard'
        END
    HAVING
        SUM(cs.cs_net_paid_inc_ship) > 20000
)
SELECT
    sm_type,
    sm_contract,
    order_category,
    total_net_paid,
    order_cnt,
    avg_net_paid,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM sales_by_mode
ORDER BY revenue_rank
LIMIT 100
