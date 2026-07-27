WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_returning_cdemo_sk,
        cr.cr_catalog_page_sk,
        cr.cr_returning_addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 50.00                     -- predicate 1
      AND cr.cr_store_credit < 100.00                     -- predicate 2
      AND cr.cr_return_quantity BETWEEN 1 AND 5          -- predicate 3
      AND cr.cr_returning_addr_sk IN (4104524, 1013766, 562952) -- predicate 4
      AND cr.cr_returned_date_sk >= 2450000               -- predicate 5
),
agg_data AS (
    SELECT
        cp.cp_department            AS department,
        i.i_brand                   AS brand,
        cd.cd_education_status      AS education_status,
        COUNT(DISTINCT fr.cr_returning_addr_sk) AS distinct_customers,
        SUM(fr.cr_return_amount)    AS total_return_amount,
        AVG(fr.cr_return_amount)    AS avg_return_amount,
        MIN(fr.cr_return_amount)    AS min_return_amount,
        MAX(fr.cr_return_amount)    AS max_return_amount,
        SUM(p.p_cost)               AS total_promo_cost
    FROM filtered_returns fr
    JOIN item i
        ON fr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    JOIN catalog_page cp
        ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
        ON fr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'          -- predicate 6
      AND i.i_manufact = 'esecallyable'                    -- predicate 7
      AND cd.cd_education_status = 'Advanced Degree'     -- predicate 8
      AND cp.cp_department = 'Electronics'                -- predicate 9
      AND p.p_discount_active = 'Y'                       -- predicate 10
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_cost > 1000.00
        )                                                   -- predicate 11 (subquery)
    GROUP BY cp.cp_department, i.i_brand, cd.cd_education_status
)
SELECT
    department,
    brand,
    education_status,
    distinct_customers,
    total_return_amount,
    avg_return_amount,
    min_return_amount,
    max_return_amount,
    total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY total_return_amount DESC) AS dept_rank
FROM agg_data
ORDER BY total_return_amount DESC
LIMIT 100
