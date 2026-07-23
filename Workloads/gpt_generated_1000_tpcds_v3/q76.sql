/*
Goal: Identify items with high net loss from store and web returns, broken down by return reason, and compare the loss to total catalog sales for each item. The query aggregates returns, filters by net loss thresholds, joins to item and reason tables, uses a UNION ALL to combine store and web return data, includes a scalar subquery for total sales, and limits the result to the top 100 records.
*/
WITH
store_returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2002-12-31'
    GROUP BY i.i_item_sk, i.i_product_name, r.r_reason_desc
    HAVING SUM(sr.sr_net_loss) > 1000
),
web_returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2002-12-31'
    GROUP BY i.i_item_sk, i.i_product_name, r.r_reason_desc
    HAVING SUM(wr.wr_net_loss) > 500
)
SELECT
    combined.i_item_sk,
    combined.i_product_name,
    combined.r_reason_desc,
    combined.net_loss,
    combined.return_cnt,
    combined.return_channel,
    combined.total_sales
FROM (
    SELECT
        sra.i_item_sk,
        sra.i_product_name,
        sra.r_reason_desc,
        sra.store_net_loss AS net_loss,
        sra.store_return_cnt AS return_cnt,
        'store' AS return_channel,
        (
            SELECT SUM(cs.cs_net_paid_inc_ship_tax)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = sra.i_item_sk
        ) AS total_sales
    FROM store_returns_agg sra

    UNION ALL

    SELECT
        wra.i_item_sk,
        wra.i_product_name,
        wra.r_reason_desc,
        wra.web_net_loss AS net_loss,
        wra.web_return_cnt AS return_cnt,
        'web' AS return_channel,
        (
            SELECT SUM(cs.cs_net_paid_inc_ship_tax)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = wra.i_item_sk
        ) AS total_sales
    FROM web_returns_agg wra
) combined
ORDER BY combined.net_loss DESC
LIMIT 100
