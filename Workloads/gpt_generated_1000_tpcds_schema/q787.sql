WITH returns_aggregated AS (
    SELECT
        COALESCE(sr.sr_returned_date_sk, wr.wr_returned_date_sk) AS return_date_sk,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns_cnt
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
        ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
    GROUP BY COALESCE(sr.sr_returned_date_sk, wr.wr_returned_date_sk)
)
SELECT
    d.d_date,
    d.d_day_name,
    CONCAT(d.d_day_name, '_', CAST(d.d_month_seq AS VARCHAR)) AS day_month_key,
    REGEXP_EXTRACT(d.d_date_id, '(\\w{3})$', 1) AS date_id_suffix,
    ra.store_net_loss,
    ra.web_net_loss,
    (ra.store_net_loss + ra.web_net_loss) AS total_net_loss,
    ra.store_returns_cnt,
    ra.web_returns_cnt,
    (
        SELECT AVG(cs.cs_net_profit)
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk = d.d_date_sk
    ) AS avg_daily_profit
FROM returns_aggregated ra
JOIN date_dim d
    ON ra.return_date_sk = d.d_date_sk
WHERE d.d_day_name LIKE 'S%'
  AND REGEXP_LIKE(d.d_date_id, '^A{9}.*$')
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cs.cs_sold_date_sk = d.d_date_sk
          AND cs.cs_net_profit > 1000
          AND REGEXP_LIKE(cc.cc_name, '^.*Center$')
    )
ORDER BY total_net_loss DESC
LIMIT 100
