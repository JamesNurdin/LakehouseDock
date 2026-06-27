WITH
    -- Aggregate store sales by year, month, gender and marital status
    store_sales_agg AS (
        SELECT
            'store' AS channel,
            ds.d_year,
            ds.d_month_seq,
            cd.cd_gender,
            cd.cd_marital_status,
            SUM(ss.ss_net_profit)          AS sales_profit,
            SUM(ss.ss_quantity)            AS quantity_sold,
            0                               AS return_loss,
            0                               AS quantity_returned
        FROM store_sales ss
        JOIN date_dim ds   ON ss.ss_sold_date_sk   = ds.d_date_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        GROUP BY ds.d_year, ds.d_month_seq, cd.cd_gender, cd.cd_marital_status
    ),
    -- Aggregate store returns by year, month, gender and marital status
    store_returns_agg AS (
        SELECT
            'store' AS channel,
            dr.d_year,
            dr.d_month_seq,
            cd.cd_gender,
            cd.cd_marital_status,
            0                               AS sales_profit,
            0                               AS quantity_sold,
            SUM(sr.sr_net_loss)            AS return_loss,
            SUM(sr.sr_return_quantity)     AS quantity_returned
        FROM store_returns sr
        JOIN date_dim dr   ON sr.sr_returned_date_sk = dr.d_date_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        GROUP BY dr.d_year, dr.d_month_seq, cd.cd_gender, cd.cd_marital_status
    ),
    -- Aggregate catalog sales
    catalog_sales_agg AS (
        SELECT
            'catalog' AS channel,
            ds.d_year,
            ds.d_month_seq,
            cd.cd_gender,
            cd.cd_marital_status,
            SUM(cs.cs_net_profit)          AS sales_profit,
            SUM(cs.cs_quantity)            AS quantity_sold,
            0                               AS return_loss,
            0                               AS quantity_returned
        FROM catalog_sales cs
        JOIN date_dim ds   ON cs.cs_sold_date_sk   = ds.d_date_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY ds.d_year, ds.d_month_seq, cd.cd_gender, cd.cd_marital_status
    ),
    -- Aggregate catalog returns
    catalog_returns_agg AS (
        SELECT
            'catalog' AS channel,
            dr.d_year,
            dr.d_month_seq,
            cd.cd_gender,
            cd.cd_marital_status,
            0                               AS sales_profit,
            0                               AS quantity_sold,
            SUM(cr.cr_net_loss)            AS return_loss,
            SUM(cr.cr_return_quantity)     AS quantity_returned
        FROM catalog_returns cr
        JOIN date_dim dr   ON cr.cr_returned_date_sk = dr.d_date_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        GROUP BY dr.d_year, dr.d_month_seq, cd.cd_gender, cd.cd_marital_status
    ),
    -- Aggregate web sales
    web_sales_agg AS (
        SELECT
            'web' AS channel,
            ds.d_year,
            ds.d_month_seq,
            cd.cd_gender,
            cd.cd_marital_status,
            SUM(ws.ws_net_profit)          AS sales_profit,
            SUM(ws.ws_quantity)            AS quantity_sold,
            0                               AS return_loss,
            0                               AS quantity_returned
        FROM web_sales ws
        JOIN date_dim ds   ON ws.ws_sold_date_sk   = ds.d_date_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY ds.d_year, ds.d_month_seq, cd.cd_gender, cd.cd_marital_status
    ),
    -- Aggregate web returns
    web_returns_agg AS (
        SELECT
            'web' AS channel,
            dr.d_year,
            dr.d_month_seq,
            cd.cd_gender,
            cd.cd_marital_status,
            0                               AS sales_profit,
            0                               AS quantity_sold,
            SUM(wr.wr_net_loss)            AS return_loss,
            SUM(wr.wr_return_quantity)     AS quantity_returned
        FROM web_returns wr
        JOIN date_dim dr   ON wr.wr_returned_date_sk = dr.d_date_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        GROUP BY dr.d_year, dr.d_month_seq, cd.cd_gender, cd.cd_marital_status
    ),
    -- Union all channel‑level aggregates
    combined AS (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM store_returns_agg
        UNION ALL
        SELECT * FROM catalog_sales_agg
        UNION ALL
        SELECT * FROM catalog_returns_agg
        UNION ALL
        SELECT * FROM web_sales_agg
        UNION ALL
        SELECT * FROM web_returns_agg
    ),
    -- Final aggregation per channel, month and demographic slice
    final_agg AS (
        SELECT
            channel,
            d_year,
            d_month_seq,
            cd_gender,
            cd_marital_status,
            SUM(sales_profit) - SUM(return_loss)                         AS net_profit,
            SUM(quantity_sold)                                            AS total_quantity_sold,
            SUM(quantity_returned)                                         AS total_quantity_returned,
            CASE WHEN SUM(quantity_sold) > 0
                 THEN SUM(quantity_returned) / CAST(SUM(quantity_sold) AS double)
                 ELSE 0
            END                                                          AS return_rate
        FROM combined
        GROUP BY channel, d_year, d_month_seq, cd_gender, cd_marital_status
    )
SELECT
    channel,
    d_year,
    d_month_seq,
    cd_gender,
    cd_marital_status,
    net_profit,
    total_quantity_sold,
    total_quantity_returned,
    return_rate,
    ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_month_seq ORDER BY net_profit DESC) AS rank_by_profit
FROM final_agg
WHERE d_year = 2001
ORDER BY channel, d_year, d_month_seq, rank_by_profit
LIMIT 100
