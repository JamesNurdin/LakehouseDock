WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    cs.cs_item_sk,
    cd.cd_gender,
    MIN(sm.sm_carrier) AS carrier,
    MAX(CASE WHEN cs.cs_quantity > 10 THEN 'High' ELSE 'Low' END) AS qty_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_returns,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = cs.cs_item_sk
    ) AS avg_store_net_paid,
    GROUPING(cs.cs_item_sk) AS grp_item,
    GROUPING(cd.cd_gender) AS grp_gender
FROM cs_sample cs
FULL OUTER JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
WHERE
    cs.cs_quantity > 5
    AND cs.cs_sales_price > 100.00
    AND ss.ss_list_price BETWEEN 50 AND 200
    AND r.r_reason_desc LIKE '%service%'
    AND td.t_hour = 14
    AND sm.sm_carrier = 'UPS'
GROUP BY GROUPING SETS (
    (cs.cs_item_sk, cd.cd_gender),
    (cs.cs_item_sk),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
