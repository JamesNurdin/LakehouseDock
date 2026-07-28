WITH filtered_items AS (
    SELECT DISTINCT i.i_item_sk,
                    i.i_brand,
                    i.i_item_desc,
                    i.i_product_name
    FROM item i
    WHERE regexp_like(i.i_item_desc, '(?i)(black|white)')
      AND i.i_product_name LIKE '%Special%'
),
sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        fi.i_brand,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
        concat(s.s_store_name, ' - ', CAST(d.d_year AS varchar)) AS store_year,
        substring(i.i_item_id, 1, 5) AS item_prefix
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
    )
    GROUP BY s.s_store_sk,
             s.s_store_name,
             d.d_year,
             fi.i_brand,
             i.i_item_id
)
SELECT
    s_store_name,
    d_year,
    i_brand,
    net_paid,
    distinct_orders,
    store_year,
    item_prefix,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY net_paid DESC) AS rank_by_store
FROM sales_agg
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE sr2.sr_store_sk = sales_agg.s_store_sk
      AND d2.d_year = sales_agg.d_year
)
ORDER BY net_paid DESC, s_store_name
LIMIT 100
