WITH sales_daily AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_quantity) AS total_qty
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk >= 20000101
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_daily AS (
    SELECT
        sr.sr_item_sk AS cs_item_sk,
        sr.sr_returned_date_sk AS cs_sold_date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk >= 20000101
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
),
combined_daily AS (
    SELECT
        s.cs_item_sk,
        s.cs_sold_date_sk,
        s.total_paid - COALESCE(r.total_return_amt, 0) AS net_amount,
        s.total_qty - COALESCE(r.return_cnt, 0) AS net_quantity
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
    cd.net_amount,
    SUM(cd.net_amount) OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.cs_sold_date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_sum_7,
    ROW_NUMBER() OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.cs_sold_date_sk DESC) AS rev_day_rank,
    CASE WHEN cd.net_quantity > 0 THEN 'Positive Qty' ELSE 'Zero/Neg Qty' END AS qty_flag,
    CASE WHEN EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND cd.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk AND p.p_discount_active = 'Y') THEN 'Promo' ELSE 'No Promo' END AS promo_flag
FROM combined_daily cd
JOIN item i ON cd.cs_item_sk = i.i_item_sk
WHERE cd.net_amount > 0
ORDER BY cd.cs_item_sk, cd.cs_sold_date_sk DESC
LIMIT 150
