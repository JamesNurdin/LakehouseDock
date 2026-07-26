WITH sales_daily AS (
    SELECT
        cs.cs_item_sk,
        DATE_TRUNC('day', FROM_UNIXTIME(cs.cs_sold_date_sk)) AS sold_day,
        SUM(cs.cs_ext_sales_price) AS daily_sales
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 19980101 AND 19981231
    GROUP BY cs.cs_item_sk, DATE_TRUNC('day', FROM_UNIXTIME(cs.cs_sold_date_sk))
),
returns_daily AS (
    SELECT
        sr.sr_item_sk AS cs_item_sk,
        DATE_TRUNC('day', FROM_UNIXTIME(sr.sr_returned_date_sk)) AS sold_day,
        SUM(sr.sr_return_amt) AS daily_returns
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 19980101 AND 19981231
    GROUP BY sr.sr_item_sk, DATE_TRUNC('day', FROM_UNIXTIME(sr.sr_returned_date_sk))
),
combined_daily AS (
    SELECT
        s.cs_item_sk,
        s.sold_day,
        s.daily_sales - COALESCE(r.daily_returns,0) AS net_daily_sales
    FROM sales_daily s
    LEFT JOIN returns_daily r ON s.cs_item_sk = r.cs_item_sk AND s.sold_day = r.sold_day
)
SELECT
    cd.cs_item_sk,
    i.i_item_id,
    i.i_product_name,
    cd.sold_day,
    cd.net_daily_sales,
    SUM(cd.net_daily_sales) OVER (PARTITION BY cd.cs_item_sk ORDER BY cd.sold_day ROWS UNBOUNDED PRECEDING) AS cumulative_sales,
    COUNT(*) OVER (PARTITION BY cd.cs_item_sk) AS trading_days,
    CASE WHEN cd.net_daily_sales = (SELECT MAX(net_daily_sales) FROM combined_daily WHERE cs_item_sk = cd.cs_item_sk) THEN 'Peak Day' ELSE 'Normal Day' END AS day_type,
    CASE WHEN EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND cd.sold_day BETWEEN FROM_UNIXTIME(p.p_start_date_sk) AND FROM_UNIXTIME(p.p_end_date_sk) AND p.p_discount_active = 'Y') THEN 'Active Promo' ELSE 'No Promo' END AS promo_status
FROM combined_daily cd
JOIN item i ON cd.cs_item_sk = i.i_item_sk
ORDER BY cd.cs_item_sk, cd.sold_day DESC
LIMIT 180
