WITH combined AS (
    -- Store sales (positive amounts)
    SELECT ds.d_year   AS year,
           ds.d_moy   AS month,
           cd.cd_gender AS gender,
           'store'    AS channel,
           ss.ss_net_paid AS amount
    FROM store_sales ss
    JOIN date_dim ds   ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    -- Store returns (negative amounts)
    SELECT dr.d_year   AS year,
           dr.d_moy   AS month,
           cd.cd_gender AS gender,
           'store'    AS channel,
           -sr.sr_net_loss AS amount
    FROM store_returns sr
    JOIN date_dim dr   ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    -- Catalog sales (positive amounts)
    SELECT ds.d_year   AS year,
           ds.d_moy   AS month,
           cd.cd_gender AS gender,
           'catalog'  AS channel,
           cs.cs_net_paid AS amount
    FROM catalog_sales cs
    JOIN date_dim ds   ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    -- Catalog returns (negative amounts)
    SELECT dr.d_year   AS year,
           dr.d_moy   AS month,
           cd.cd_gender AS gender,
           'catalog'  AS channel,
           -cr.cr_net_loss AS amount
    FROM catalog_returns cr
    JOIN date_dim dr   ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    -- Web sales (positive amounts)
    SELECT ds.d_year   AS year,
           ds.d_moy   AS month,
           cd.cd_gender AS gender,
           'web'      AS channel,
           ws.ws_net_paid AS amount
    FROM web_sales ws
    JOIN date_dim ds   ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    -- Web returns (negative amounts)
    SELECT dr.d_year   AS year,
           dr.d_moy   AS month,
           cd.cd_gender AS gender,
           'web'      AS channel,
           -wr.wr_net_loss AS amount
    FROM web_returns wr
    JOIN date_dim dr   ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
)
SELECT
    year,
    month,
    gender,
    channel,
    SUM(amount) AS net_revenue
FROM combined
GROUP BY year, month, gender, channel
ORDER BY year, month, channel, gender
