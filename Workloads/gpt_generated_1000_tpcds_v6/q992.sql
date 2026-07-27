WITH catalog_profit AS ( 
    SELECT cs.cs_sold_date_sk AS period_date_sk,
           'CatalogSales' AS channel,
           SUM(cs.cs_net_profit) AS metric_value
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
      AND (SELECT MAX(r_reason_sk) FROM reason) > 0
    GROUP BY cs.cs_sold_date_sk
),
store_loss AS ( 
    SELECT sr.sr_returned_date_sk AS period_date_sk,
           'StoreReturns' AS channel,
           SUM(sr.sr_net_loss) AS metric_value
    FROM store_returns sr
    JOIN time_dim td2 ON sr.sr_return_time_sk = td2.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE td2.t_hour BETWEEN 9 AND 12
      AND r.r_reason_desc LIKE '%size%'
      AND EXISTS ( 
            SELECT 1 
            FROM web_returns wr 
            WHERE wr.wr_reason_sk = sr.sr_reason_sk 
              AND wr.wr_return_quantity > 0
          )
    GROUP BY sr.sr_returned_date_sk
)
SELECT period_date_sk,
       channel,
       metric_value
FROM ( 
    SELECT * FROM catalog_profit
    UNION ALL
    SELECT * FROM store_loss
) AS combined
ORDER BY period_date_sk DESC,
         metric_value DESC
LIMIT 100
