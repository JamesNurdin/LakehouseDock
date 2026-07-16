SELECT d.d_year,
       sum(coalesce(s.total_sales, 0)) AS total_sales,
       sum(coalesce(r.total_returns, 0)) AS total_returns,
       sum(coalesce(s.total_sales, 0)) - sum(coalesce(r.total_returns, 0)) AS net,
       case when sum(coalesce(r.total_returns, 0)) = 0 then null
            else sum(coalesce(s.total_sales, 0)) / sum(coalesce(r.total_returns, 0))
       end AS sales_to_return_ratio
FROM date_dim d
LEFT JOIN (
    SELECT date_sk, sum(net_paid) AS total_sales
    FROM (
        SELECT ss_sold_date_sk AS date_sk, ss_net_paid AS net_paid FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk AS date_sk, cs_net_paid AS net_paid FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk AS date_sk, ws_net_paid AS net_paid FROM web_sales
    ) sales_union
    GROUP BY date_sk
) s ON d.d_date_sk = s.date_sk
LEFT JOIN (
    SELECT date_sk, sum(net_loss) AS total_returns
    FROM (
        SELECT sr_returned_date_sk AS date_sk, sr_net_loss AS net_loss FROM store_returns
        UNION ALL
        SELECT cr_returned_date_sk AS date_sk, cr_net_loss AS net_loss FROM catalog_returns
        UNION ALL
        SELECT wr_returned_date_sk AS date_sk, wr_net_loss AS net_loss FROM web_returns
    ) returns_union
    GROUP BY date_sk
) r ON d.d_date_sk = r.date_sk
WHERE d.d_year = 1999
GROUP BY d.d_year
ORDER BY d.d_year
