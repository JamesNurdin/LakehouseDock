WITH
union_pages AS (
    SELECT cp_catalog_page_sk, cp_type
    FROM catalog_page
    WHERE cp_type = 'monthly'

    UNION ALL

    SELECT cp_catalog_page_sk, cp_type
    FROM catalog_page
    WHERE cp_type = 'quarterly'
),
intersect_pages AS (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_type = 'monthly'

    INTERSECT

    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_end_date_sk > 2450900
),
base_join AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.web_name,
        w.web_market_manager,
        i.inv_quantity_on_hand,
        i.inv_item_sk,
        cp.cp_type,
        cp.cp_catalog_page_number,
        cp.cp_catalog_page_sk,
        CASE
            WHEN cp.cp_type = 'monthly' THEN 'M'
            WHEN cp.cp_type = 'quarterly' THEN 'Q'
            ELSE 'O'
        END AS cp_type_cd,
        SUM(i.inv_quantity_on_hand) OVER (PARTITION BY d.d_year) AS year_qty_running_total
    FROM date_dim d
    INNER JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT OUTER JOIN catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    INNER JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2001
        AND i.inv_quantity_on_hand > 0
        AND w.web_market_manager = 'John Sheppard'
        AND (cp.cp_type IN ('monthly', 'quarterly') OR cp.cp_type IS NULL)
        AND cp.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_pages)
        AND EXISTS (SELECT 1 FROM union_pages up WHERE up.cp_catalog_page_sk = cp.cp_catalog_page_sk)
),
agg_per_group AS (
    SELECT
        bj.d_year,
        bj.web_name,
        bj.cp_type_cd,
        SUM(bj.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT bj.inv_item_sk) AS distinct_items,
        AVG(bj.inv_quantity_on_hand) AS avg_qty,
        (SELECT AVG(inv_quantity_on_hand) FROM inventory) AS overall_avg_qty
    FROM base_join bj
    GROUP BY
        bj.d_year,
        bj.web_name,
        bj.cp_type_cd
    HAVING
        SUM(bj.inv_quantity_on_hand) > 1000
)
SELECT
    apg.d_year,
    apg.web_name,
    apg.cp_type_cd,
    apg.total_qty,
    apg.distinct_items,
    apg.avg_qty,
    apg.overall_avg_qty,
    RANK() OVER (ORDER BY apg.total_qty DESC) AS total_qty_rank
FROM agg_per_group apg
ORDER BY apg.total_qty DESC
LIMIT 100
