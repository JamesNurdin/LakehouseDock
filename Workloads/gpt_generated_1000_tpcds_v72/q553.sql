SELECT
    year,
    channel,
    total_amount,
    category,
    description
FROM (
    SELECT
        d.d_year AS year,
        'Catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_amount,
        CASE
            WHEN SUM(cs.cs_net_profit) > 1000000 THEN 'High'
            WHEN SUM(cs.cs_net_profit) > 500000  THEN 'Medium'
            ELSE 'Low'
        END AS category,
        CONCAT(cc.cc_name, ' (', cc.cc_city, ')') AS description
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE REGEXP_LIKE(cc.cc_name, 'Center')
      AND cc.cc_state LIKE 'CA%'
    GROUP BY d.d_year, cc.cc_name, cc.cc_city

    UNION ALL

    SELECT
        d.d_year AS year,
        'Store' AS channel,
        SUM(sr.sr_net_loss) AS total_amount,
        CASE
            WHEN SUM(sr.sr_net_loss) > 500000 THEN 'HighLoss'
            ELSE 'LowLoss'
        END AS category,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS description
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_city LIKE 'San%'
    GROUP BY d.d_year, s.s_store_name, s.s_city
) t
ORDER BY year DESC, total_amount DESC
