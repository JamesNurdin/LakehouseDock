WITH sales_daily AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_profit) AS profit_sum,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk % 7 = 0  -- only Saturdays
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_daily AS (
    SELECT
        sr.sr_item_sk AS cs_item_sk,
        sr.sr_returned_date_sk AS cs_sold_date_sk,
        SUM(sr.sr_net_loss) AS loss_sum,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk % 7 = 0
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
),
combined_daily AS (
    SELECT
        s.cs_item_sk,
        s.cs_sold_date_sk,
        s.profit_sum,
        s.txn_cnt,
        COALESCE(r.loss_sum,0) AS loss_sum,
        COALESCE(r.return_cnt,0) AS return_cnt,
        s.profit_sum - COALESCE(r.loss_sum,0) AS net_profit,
        s.txn_cnt - COALESCE(r.return_cnt,0) AS net_txn
    FROM sales_daily s
    LEFT JOIN returns_daily r ON s.cs_item_sk = r.cs_item_sk AND s.cs_sold_date_sk = r.cs_sold_date_sk
)
SELECT
    cd.cs_item_sk,
    i.i_item_id,
    i.i_product_name,
    cd.cs_sold_date_sk,
    cd.net_profit,
    cd.net_txn,
    AVG(cd.net_profit) OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.cs_sold_date_sk ROWS BETWEEN 4 PRECEDING AND 1 PRECEDING) AS lag_avg_profit,
    LAG(cd.net_profit,1) OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.cs_sold_date_sk) AS prev_day_profit,
    CASE WHEN cd.net_profit > COALESCE(LAG(cd.net_profit,1) OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.cs_sold_date_sk),0) THEN 'Increase' ELSE 'Decrease/Flat' END AS profit_trend,
    CASE WHEN EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND cd.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk AND p.p_discount_active = 'Y') THEN 'Promo' ELSE 'No Promo' END AS promo_flag
FROM combined_daily cd
JOIN item i ON cd.cs_item_sk = i.i_item_sk
ORDER BY cd.cs_item_sk, cd.cs_sold_date_sk
LIMIT 200
