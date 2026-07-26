WITH sales_daily AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_profit) AS sales_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_daily AS (
    SELECT
        sr.sr_item_sk AS cs_item_sk,
        sr.sr_returned_date_sk AS cs_sold_date_sk,
        SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
),
combined_daily AS (
    SELECT
        s.cs_item_sk,
        s.cs_sold_date_sk,
        s.sales_profit,
        COALESCE(r.return_loss, 0) AS return_loss,
        s.sales_profit - COALESCE(r.return_loss, 0) AS net_profit
    FROM sales_daily s
    LEFT JOIN returns_daily r
        ON s.cs_item_sk = r.cs_item_sk
        AND s.cs_sold_date_sk = r.cs_sold_date_sk
)
SELECT
    cd.cs_item_sk,
    i.i_item_id,
    i.i_product_name,
    cd.cs_sold_date_sk,
    cd.net_profit,
    AVG(cd.net_profit) OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3,
    RANK() OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.net_profit DESC) AS profit_rank,
    CASE
        WHEN cd.net_profit > AVG(cd.net_profit) OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) THEN 'Above MA'
        ELSE 'Below MA'
    END AS ma_flag,
    CASE
        WHEN (SELECT MAX(p.p_discount_active) FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND cd.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) = 'Y' THEN 'Promotion Active'
        ELSE 'No Promotion'
    END AS promo_status
FROM combined_daily cd
JOIN item i
    ON cd.cs_item_sk = i.i_item_sk
ORDER BY cd.cs_item_sk, cd.cs_sold_date_sk
LIMIT 200
