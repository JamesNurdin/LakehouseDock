WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_credit_rating,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt
    FROM store_sales ss
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd.cd_dep_employed_count >= 2
      AND ca.ca_city IN ('Springfield', 'Glendale')
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND ss.ss_quantity > 1
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_credit_rating
    HAVING SUM(ss.ss_net_profit) > 0
),
return_agg AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    INNER JOIN customer c2
        ON sr.sr_customer_sk = c2.c_customer_sk
    WHERE sr.sr_return_quantity > 0
    GROUP BY sr.sr_customer_sk
)
SELECT
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.ca_city,
    sa.cd_credit_rating,
    sa.total_store_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (sa.total_store_profit - COALESCE(ra.total_return_loss, 0)) AS net_contribution,
    ROW_NUMBER() OVER (PARTITION BY sa.ca_city ORDER BY (sa.total_store_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS city_rank,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = sa.c_customer_sk
          AND cs.cs_ext_sales_price > 200
    ) AS catalog_sales_gt_200_cnt
FROM sales_agg sa
LEFT JOIN return_agg ra
    ON ra.sr_customer_sk = sa.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_bill_customer_sk = sa.c_customer_sk
      AND cs.cs_ext_sales_price > 200
)
ORDER BY net_contribution DESC
LIMIT 100
