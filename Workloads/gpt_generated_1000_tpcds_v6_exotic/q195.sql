WITH filtered AS (
    SELECT
        cs.cs_ext_sales_price,
        sr.sr_refunded_cash,
        r.r_reason_desc,
        cd.cd_gender
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cs.cs_quantity > 5                                   -- predicate 1
      AND cs.cs_net_profit > 0                                 -- predicate 2
      AND sr.sr_return_quantity > 10                           -- predicate 3
      AND sr.sr_return_ship_cost > 30                           -- predicate 4
      AND r.r_reason_id LIKE 'AAAAAAAA%'                       -- predicate 5
      AND cd.cd_gender IN ('M', 'F')                           -- predicate 6
      AND cs.cs_ext_sales_price > 100                           -- predicate 7
      AND EXISTS (
            SELECT 1
            FROM web_sales ws
            WHERE ws.ws_bill_cdemo_sk = cd.cd_demo_sk
              AND ws.ws_quantity BETWEEN 1 AND 10
              AND ws.ws_net_paid > 100
        )
),
aggregated AS (
    SELECT
        r_reason_desc,
        cd_gender,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(sr_refunded_cash) AS total_refunds,
        SUM(cs_ext_sales_price - sr_refunded_cash) AS total_sales
    FROM filtered
    GROUP BY GROUPING SETS (
        (r_reason_desc, cd_gender),
        (r_reason_desc),
        ()
    )
)
SELECT
    r_reason_desc,
    cd_gender,
    total_catalog_sales,
    total_refunds,
    total_sales,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_sales DESC) AS rank_within_reason
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
