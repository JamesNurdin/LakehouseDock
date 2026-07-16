WITH sales AS (
    SELECT 'store' AS channel,
           ss.ss_store_sk AS entity_sk,
           ss.ss_sold_date_sk AS date_sk,
           SUM(ss.ss_net_paid) AS net_paid,
           SUM(ss.ss_net_profit) AS net_profit,
           CAST(0 AS decimal(7,2)) AS return_amt,
           CAST(0 AS decimal(7,2)) AS return_loss
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk

    UNION ALL

    SELECT 'store' AS channel,
           sr.sr_store_sk,
           sr.sr_returned_date_sk,
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2)),
           SUM(sr.sr_return_amt),
           SUM(sr.sr_net_loss)
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk

    UNION ALL

    SELECT 'catalog' AS channel,
           cs.cs_call_center_sk,
           cs.cs_sold_date_sk,
           SUM(cs.cs_net_paid),
           SUM(cs.cs_net_profit),
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2))
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_sold_date_sk

    UNION ALL

    SELECT 'catalog' AS channel,
           cr.cr_call_center_sk,
           cr.cr_returned_date_sk,
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2)),
           SUM(cr.cr_return_amount),
           SUM(cr.cr_net_loss)
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk, cr.cr_returned_date_sk

    UNION ALL

    SELECT 'web' AS channel,
           ws.ws_web_page_sk,
           ws.ws_sold_date_sk,
           SUM(ws.ws_net_paid),
           SUM(ws.ws_net_profit),
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2))
    FROM web_sales ws
    GROUP BY ws.ws_web_page_sk, ws.ws_sold_date_sk

    UNION ALL

    SELECT 'web' AS channel,
           wr.wr_web_page_sk,
           wr.wr_returned_date_sk,
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2)),
           SUM(wr.wr_return_amt),
           SUM(wr.wr_net_loss)
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk, wr.wr_returned_date_sk
),
monthly AS (
    SELECT d.d_year,
           d.d_month_seq,
           s.channel,
           SUM(s.net_paid) AS total_net_paid,
           SUM(s.net_profit) AS total_net_profit,
           SUM(s.return_amt) AS total_return_amt,
           SUM(s.return_loss) AS total_return_loss
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY d.d_year, d.d_month_seq, s.channel
    HAVING SUM(s.net_paid) > 0
)
SELECT
    d_year,
    d_month_seq,
    channel,
    total_net_paid,
    total_net_profit,
    total_return_amt,
    total_return_loss,
    (total_net_profit - total_return_loss) / total_net_paid AS profit_margin,
    RANK() OVER (PARTITION BY channel ORDER BY (total_net_profit - total_return_loss) DESC) AS profit_rank,
    ROUND(
        (total_net_paid - LAG(total_net_paid) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq))
        / NULLIF(LAG(total_net_paid) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq), 0),
        4
    ) AS mom_growth,
    SUM(total_net_profit - total_return_loss) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq ROWS UNBOUNDED PRECEDING) AS cumulative_profit,
    ROUND(
        SUM(total_net_profit - total_return_loss) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq ROWS UNBOUNDED PRECEDING)
        / NULLIF(SUM(total_net_paid) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq ROWS UNBOUNDED PRECEDING), 0),
        4
    ) AS cumulative_margin
FROM monthly
ORDER BY d_year, d_month_seq, channel
