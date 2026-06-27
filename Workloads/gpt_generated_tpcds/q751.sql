WITH combined_sales AS (
    -- Catalog sales
    SELECT
        d.d_year                     AS d_year,
        cd.cd_gender                 AS cd_gender,
        cs.cs_net_profit             AS net_profit,
        cs.cs_quantity               AS quantity,
        'Catalog'                    AS channel
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'

    UNION ALL

    -- Store sales
    SELECT
        d.d_year                     AS d_year,
        cd.cd_gender                 AS cd_gender,
        ss.ss_net_profit             AS net_profit,
        ss.ss_quantity               AS quantity,
        'Store'                      AS channel
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'

    UNION ALL

    -- Web sales
    SELECT
        d.d_year                     AS d_year,
        cd.cd_gender                 AS cd_gender,
        ws.ws_net_profit             AS net_profit,
        ws.ws_quantity               AS quantity,
        'Web'                        AS channel
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
)
SELECT
    channel,
    d_year,
    cd_gender,
    SUM(net_profit)                               AS total_net_profit,
    SUM(quantity)                                 AS total_quantity,
    CASE WHEN SUM(quantity) = 0 THEN 0
         ELSE SUM(net_profit) / SUM(quantity) END AS avg_net_profit_per_unit
FROM combined_sales
GROUP BY channel, d_year, cd_gender
ORDER BY channel, d_year, cd_gender
