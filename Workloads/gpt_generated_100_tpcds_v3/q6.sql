SELECT
    year,
    entity_id,
    entity_type,
    net_amount
FROM (
    SELECT
        d.d_year AS year,
        cc.cc_call_center_id AS entity_id,
        'CALL_CENTER' AS entity_type,
        SUM(cs.cs_net_profit) AS net_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cc.cc_city = 'Harmony'
    GROUP BY d.d_year, cc.cc_call_center_id

    UNION ALL

    SELECT
        d.d_year AS year,
        s.s_store_id AS entity_id,
        'STORE' AS entity_type,
        -SUM(wr.wr_net_loss) AS net_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND s.s_city = 'Cedar Grove'
    GROUP BY d.d_year, s.s_store_id
) AS combined
ORDER BY year DESC, net_amount DESC
LIMIT 100
