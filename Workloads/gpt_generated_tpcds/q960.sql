WITH
    -- Sales data from catalog and web channels
    sales_raw AS (
        SELECT
            d.d_year AS year,
            cd.cd_gender AS gender,
            cs.cs_net_profit AS profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        UNION ALL
        SELECT
            d.d_year,
            cd.cd_gender,
            ws.ws_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    ),
    -- Returns (loss) data from all three channels
    returns_raw AS (
        SELECT
            d.d_year AS year,
            cd.cd_gender AS gender,
            cr.cr_net_loss AS loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        UNION ALL
        SELECT
            d.d_year,
            cd.cd_gender,
            wr.wr_net_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        UNION ALL
        SELECT
            d.d_year,
            cd.cd_gender,
            sr.sr_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    ),
    -- Aggregate sales profit by year and gender
    sales_agg AS (
        SELECT
            year,
            gender,
            SUM(profit) AS total_sales_profit
        FROM sales_raw
        GROUP BY year, gender
    ),
    -- Aggregate returns loss by year and gender
    returns_agg AS (
        SELECT
            year,
            gender,
            SUM(loss) AS total_returns_loss
        FROM returns_raw
        GROUP BY year, gender
    )
SELECT
    COALESCE(s.year, r.year) AS year,
    COALESCE(s.gender, r.gender) AS gender,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_returns_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.year = r.year AND s.gender = r.gender
ORDER BY year, gender
