WITH store_agg AS (
    SELECT
        td.t_hour AS hour,
        'store' AS source,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS cnt
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE td.t_am_pm = 'PM'
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs
            WHERE cs.cs_bill_customer_sk = sr.sr_customer_sk
              AND cs.cs_sold_time_sk = td.t_time_sk
        )
    GROUP BY td.t_hour
    HAVING SUM(sr.sr_net_loss) > 1000
),
web_agg AS (
    SELECT
        td.t_hour AS hour,
        'web' AS source,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_am_pm = 'PM'
      AND wr.wr_return_quantity > 1
    GROUP BY td.t_hour
    HAVING SUM(wr.wr_net_loss) > 500
)
SELECT *
FROM (
    SELECT hour, source, total_loss, cnt FROM store_agg
    UNION ALL
    SELECT hour, source, total_loss, cnt FROM web_agg
) combined
ORDER BY hour, source
LIMIT 100
