WITH sales_daily AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_daily AS (
    SELECT
        sr.sr_item_sk AS cs_item_sk,
        sr.sr_returned_date_sk AS cs_sold_date_sk,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
),
combined_daily AS (
    SELECT
        s.cs_item_sk,
        s.cs_sold_date_sk,
        s.sales_cnt,
        s.avg_profit,
        COALESCE(r.return_cnt,0) AS return_cnt,
        s.avg_profit - COALESCE(r.total_loss,0) AS adj_profit
    FROM sales_daily s
    LEFT JOIN returns_daily r ON s.cs_item_sk = r.cs_item_sk AND s.cs_sold_date_sk = r.cs_sold_date_sk
)
SELECT
    cd.cs_item_sk,
    i.i_item_id,
    i.i_product_name,
    cd.cs_sold_date_sk,
    cd.adj_profit,
    MAX(cd.adj_profit) OVER (PARTITION BY cd.cs_item_sk) AS max_adj_profit,
    MIN(cd.adj_profit) OVER (PARTITION BY cd.cs_item_sk) AS min_adj_profit,
    PERCENT_RANK() OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.adj_profit) AS profit_percentile,
    CASE WHEN cd.sales_cnt > cd.return_cnt THEN 'More Sales' ELSE 'More Returns' END AS sales_return_flag,
    CASE WHEN (SELECT COUNT(*) FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND cd.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) > 0 THEN 'Promo Exists' ELSE 'No Promo' END AS promo_exists
FROM combined_daily cd
JOIN item i ON cd.cs_item_sk = i.i_item_sk
ORDER BY cd.cs_item_sk, cd.cs_sold_date_sk
LIMIT 200
