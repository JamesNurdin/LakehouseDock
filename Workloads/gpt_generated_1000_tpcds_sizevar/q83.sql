WITH ss_filtered AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_item_sk IN (
        SELECT i2.i_item_sk
        FROM tpcds.item i2
        WHERE i2.i_current_price > 50
    )
      AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY i.i_item_id
), cs_filtered AS (
    SELECT
        i.i_item_id,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_current_price < 30
      AND i.i_rec_end_date > DATE '2000-01-01'
    GROUP BY i.i_item_id
)
SELECT * FROM ss_filtered
UNION ALL
SELECT * FROM cs_filtered
ORDER BY total_net_paid DESC
LIMIT 100
