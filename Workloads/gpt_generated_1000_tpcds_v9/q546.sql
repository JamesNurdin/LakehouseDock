WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 2
      AND ss.ss_sold_date_sk BETWEEN 2452190 AND 2452220
      AND cd.cd_gender = 'M'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
catalog_return_agg AS (
    SELECT
        i.i_item_sk,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        COUNT(*) AS catalog_return_count
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
      AND cc.cc_employees >= 200
      AND r.r_reason_desc LIKE '%return%'
    GROUP BY i.i_item_sk
),
web_return_agg AS (
    SELECT
        i.i_item_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        COUNT(*) AS web_return_count
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_tax BETWEEN 5 AND 30
      AND r.r_reason_desc LIKE '%return%'
    GROUP BY i.i_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.total_sales_amount,
    s.total_sales_profit,
    cr.total_catalog_return_amount,
    cr.total_catalog_net_loss,
    wr.total_web_return_amount,
    wr.total_web_net_loss,
    (s.total_sales_profit - COALESCE(cr.total_catalog_net_loss, 0) - COALESCE(wr.total_web_net_loss, 0)) AS net_impact,
    RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(cr.total_catalog_net_loss, 0) - COALESCE(wr.total_web_net_loss, 0)) DESC) AS profit_rank,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
    ) AS avg_catalog_return_amount,
    CASE
        WHEN COALESCE(wr.total_web_return_amount, 0) > 500 THEN 'High Web Returns'
        ELSE 'Low Web Returns'
    END AS web_return_category
FROM item i
JOIN item_sales s ON i.i_item_sk = s.i_item_sk
LEFT JOIN catalog_return_agg cr ON i.i_item_sk = cr.i_item_sk
LEFT JOIN web_return_agg wr ON i.i_item_sk = wr.i_item_sk
WHERE s.total_sales_amount > 1000
  AND i.i_current_price BETWEEN 10 AND 1000
  AND (cr.total_catalog_return_amount IS NULL OR cr.total_catalog_return_amount < 5000)
  AND (wr.total_web_return_amount IS NULL OR wr.total_web_return_amount < 3000)
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_fee > 10
    )
ORDER BY net_impact DESC
LIMIT 100
