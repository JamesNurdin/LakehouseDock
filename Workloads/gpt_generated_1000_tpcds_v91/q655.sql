WITH base AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        ss.ss_store_sk AS ss_store_sk,
        ss.ss_net_paid_inc_tax AS ss_net_paid_inc_tax,
        ss.ss_quantity AS ss_quantity,
        ss.ss_list_price AS ss_list_price,
        i.inv_quantity_on_hand AS inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'Y'
      AND d.d_year BETWEEN 1999 AND 2002
      AND i.inv_quantity_on_hand > 500
      AND ss.ss_net_paid_inc_tax > 1000
),
base2 AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        ss.ss_store_sk AS ss_store_sk,
        ss.ss_net_paid_inc_tax AS ss_net_paid_inc_tax,
        ss.ss_quantity AS ss_quantity,
        ss.ss_list_price AS ss_list_price,
        i.inv_quantity_on_hand AS inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'N'
      AND d.d_year BETWEEN 1999 AND 2002
      AND i.inv_quantity_on_hand > 500
      AND ss.ss_net_paid_inc_tax > 1000
),
agg_union AS (
    SELECT * FROM base
    UNION DISTINCT
    SELECT * FROM base2
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS sum_net_paid_inc_tax,
        SUM(ss_quantity) AS sum_quantity,
        AVG(ss_list_price) AS avg_list_price,
        SUM(inv_quantity_on_hand) AS sum_inv_quantity,
        CASE
            WHEN SUM(inv_quantity_on_hand) < 3000 THEN 'LowInventory'
            WHEN SUM(inv_quantity_on_hand) BETWEEN 3000 AND 6000 THEN 'MediumInventory'
            ELSE 'HighInventory'
        END AS inventory_category
    FROM agg_union
    GROUP BY GROUPING SETS (
        (d_year, d_month_seq, ss_store_sk),
        (d_year, d_month_seq),
        (d_year),
        ()
    )
)
SELECT
    d_year,
    d_month_seq,
    ss_store_sk,
    sum_net_paid_inc_tax,
    sum_quantity,
    avg_list_price,
    sum_inv_quantity,
    inventory_category,
    RANK() OVER (PARTITION BY d_year ORDER BY sum_net_paid_inc_tax DESC) AS yearly_revenue_rank
FROM aggregated
ORDER BY d_year DESC, d_month_seq ASC, yearly_revenue_rank ASC
LIMIT 100
