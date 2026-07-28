WITH date_range AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
)
SELECT source,
       year,
       month_seq,
       metric1,
       metric2,
       flag,
       sub_metric
FROM (
    SELECT
        'catalog' AS source,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_net_paid_inc_tax) AS metric1,
        SUM(cs.cs_net_profit)      AS metric2,
        CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'Y' ELSE 'N' END AS flag,
        (SELECT AVG(cs2.cs_ext_discount_amt)
         FROM catalog_sales cs2
         WHERE cs2.cs_sold_date_sk = d.d_date_sk) AS sub_metric
    FROM catalog_sales cs
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_date_sk

    UNION ALL

    SELECT
        'store_return' AS source,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(sr.sr_net_loss)        AS metric1,
        SUM(sr.sr_return_quantity) AS metric2,
        CASE WHEN SUM(sr.sr_net_loss) > 50000 THEN 'Y' ELSE 'N' END AS flag,
        (SELECT COUNT(DISTINCT sr2.sr_item_sk)
         FROM store_returns sr2
         WHERE sr2.sr_returned_date_sk = d.d_date_sk) AS sub_metric
    FROM store_returns sr
    JOIN date_range dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_date_sk
) AS combined
ORDER BY source, year, month_seq
LIMIT 100
