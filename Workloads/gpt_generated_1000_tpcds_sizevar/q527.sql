WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE
            WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_name, '^\\w+ Center$')
      AND cc.cc_name LIKE '%Center%'
      AND d.d_year BETWEEN 1999 AND 2001
    GROUP BY GROUPING SETS (
        (cc.cc_call_center_sk, cc.cc_name, d.d_year),
        (cc.cc_call_center_sk, cc.cc_name),
        (d.d_year)
    )
)
SELECT
    sa.cc_name,
    sa.d_year,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.profit_category,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_call_center_sk = sa.cc_call_center_sk
          AND cr.cr_return_amount > 0
    ) AS total_return_amount,
    CONCAT(sa.cc_name, ' (', CAST(sa.d_year AS varchar), ')') AS name_year_concat
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = sa.cc_call_center_sk
      AND cr2.cr_return_amount > 5000
)
ORDER BY sa.total_net_paid DESC
LIMIT 100
