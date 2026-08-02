WITH catalog_summary AS (
    SELECT
        d.d_year AS year,
        p.p_promo_id AS promo_id,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
        (SELECT SUM(cr.cr_return_amount)
         FROM catalog_returns cr
         JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
         WHERE d2.d_year = d.d_year) AS total_return_amount_year,
        SUM(inv_l.total_on_hand) AS total_inventory_on_hand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory inv
        WHERE inv.inv_date_sk = cs.cs_sold_date_sk
          AND inv.inv_item_sk = cs.cs_item_sk
    ) AS inv_l
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
        (d.d_year),
        (d.d_year, p.p_promo_id)
    )
),
store_summary AS (
    SELECT
        d.d_year AS year,
        s.s_store_name AS store_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        (SELECT SUM(wr.wr_return_amt)
         FROM web_returns wr
         JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
         WHERE d2.d_year = d.d_year) AS total_return_amount_year,
        SUM(inv_l.total_on_hand) AS total_inventory_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory inv
        WHERE inv.inv_date_sk = ss.ss_sold_date_sk
          AND inv.inv_item_sk = ss.ss_item_sk
    ) AS inv_l
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
        (d.d_year),
        (d.d_year, s.s_store_name)
    )
)
SELECT DISTINCT
    src_type,
    year,
    identifier,
    total_amount,
    unique_customers,
    total_return_amount_year,
    total_inventory_on_hand
FROM (
    SELECT
        'catalog' AS src_type,
        year,
        promo_id AS identifier,
        total_net_paid_inc_tax AS total_amount,
        unique_customers,
        total_return_amount_year,
        total_inventory_on_hand
    FROM catalog_summary
    UNION ALL
    SELECT
        'store' AS src_type,
        year,
        store_name AS identifier,
        total_net_paid_inc_tax AS total_amount,
        unique_customers,
        total_return_amount_year,
        total_inventory_on_hand
    FROM store_summary
) AS combined
ORDER BY src_type, year, identifier
